class PurchasesController < ApplicationController
  def create
    # receive:
    # bowler_identifier ----------- obvious
    # purchase_identifiers: [], --- identifiers of required items (entry fee, etc)
    # purchasable_items: [  ------- optional items + quantities desired
    #   {
    #     identifier: ...,
    #     quantity: X,
    #   },
    #   ...
    # ],
    # paypal_details: -------------- structure returned by PayPal

    load_bowler
    unless bowler.present?
      render json: nil, status: :not_found
      return
    end

    # permit and parse params (quantities come in as strings)
    params.permit!
    details = params.to_h
    details[:purchasable_items]&.each_index do |index|
      details[:purchasable_items][index][:quantity] = details[:purchasable_items][index][:quantity].to_i
    end

    paid_at = Time.zone.now
    # ppo = PaypalOrder.create(identifier: details[:paypal_details][:id], details: details[:paypal_details])
    extp = ExternalPayment.create(
      payment_type: :paypal,
      identifier: details[:paypal_details][:id],
      details: details[:paypal_details],
      tournament: tournament
    )

    purchase_identifiers = details[:purchase_identifiers] || []
    matching_purchases = bowler.purchases.unpaid.where(identifier: purchase_identifiers)
    total_credit = matching_purchases.sum(&:amount)
    matching_purchases.update_all(paid_at: paid_at, external_payment_id: extp.id)

    new_purchases = bowler.purchases.where(identifier: purchase_identifiers).to_a
    previous_paid_event_item_identifiers = bowler.purchases.event.paid.map { |p| p.purchasable_item.identifier }

    # gather purchasable items
    items = details[:purchasable_items] || []
    identifiers = items.collect { |i| i[:identifier] }
    purchasable_items = tournament.purchasable_items.where(identifier: identifiers).index_by(&:identifier)

    items.map do |item|
      identifier = item[:identifier]
      quantity = item[:quantity]
      item = purchasable_items[identifier]

      quantity.times do |i|
        new_purchases << Purchase.create(bowler: bowler,
          purchasable_item: item,
          amount: item.value,
          paid_at: paid_at,
          external_payment_id: extp.id
        )
        bowler.ledger_entries << LedgerEntry.new(
          debit: item.value,
          source: :purchase,
          identifier: item[:name]
        )
        total_credit += item.value
      end
    end

    # apply any relevant event bundle discounts
    bundle_discount_items = tournament.purchasable_items.bundle_discount
    applicable_discounts = bundle_discount_items.select do |discount|
      (identifiers + previous_paid_event_item_identifiers).intersection(discount.configuration['events']).length == discount.configuration['events'].length
    end
    applicable_discounts.map do |d|
      new_purchases << Purchase.create(bowler: bowler,
        purchasable_item: d,
        amount: d.value,
        paid_at: paid_at,
        external_payment_id: extp.id
      )
      bowler.ledger_entries << LedgerEntry.new(
        credit: d.value,
        source: :purchase,
        identifier: d.name
      )
    end
    total_credit += applicable_discounts.sum(&:value)

    # apply any relevant event-linked late fees
    late_fee_items = tournament.purchasable_items.event_linked.late_fee
    applicable_fees = late_fee_items.select do |fee|
      identifiers.include?(fee.configuration['event']) && tournament.in_late_registration?(event_linked_late_fee: fee)
    end
    applicable_fees.map do |lf|
      new_purchases << Purchase.create(bowler: bowler,
        purchasable_item: lf,
        amount: lf.value,
        paid_at: paid_at,
        external_payment_id: extp.id
      )
      linked_event = tournament.purchasable_items.event.find_by(identifier: lf.configuration['event'])
      bowler.ledger_entries << LedgerEntry.new(
        debit: lf.value,
        source: :purchase,
        identifier: "#{lf.name} (#{linked_event.name})"
      )
    end
    total_credit += applicable_fees.sum(&:value)

    unless total_credit == 0
      bowler.ledger_entries << LedgerEntry.new(
        credit: total_credit,
        source: :paypal,
        identifier: details[:paypal_details][:id]
      )
    end

    TournamentRegistration.send_receipt_email(bowler, extp.id)
    send_payment_notification(bowler, extp.identifier, total_credit, paid_at)

    TournamentRegistration.try_confirming_bowler_shift(bowler)

    if (new_purchases.empty?)
      render json: nil, status: :no_content
    else
      render json: PurchaseBlueprint.render(new_purchases), status: :created
    end
  end

  ####################################

  private

  attr_reader :tournament, :bowler

  def load_bowler
    identifier = params.require(:bowler_identifier)
    @bowler = Bowler.includes(:tournament, :person, :ledger_entries, { purchases: [:purchasable_item] })
                    .where(identifier: identifier)
                    .first
    @tournament = bowler&.tournament
  end

  def send_payment_notification(bowler, external_payment_identifier, amount, received_at = Time.zone.now)
    tournament = bowler.tournament
    contacts = tournament.contacts.payment_notifiable.individually
    contacts.each do |c|
      email = Rails.env.production? ? c.email : MailerJob::FROM
      NewPaymentNotifierJob.perform_async(bowler.id, external_payment_identifier, amount, received_at, email)
    end
  end

end

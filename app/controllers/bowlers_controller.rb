class BowlersController < ApplicationController
  wrap_parameters false

  before_action :load_bowler, only: %i(show purchase_details stripe_checkout)

  # gives us attributes: tournament, stripe_account
  include StripeUtilities

  ADDITIONAL_QUESTION_RESPONSES_ATTRS = %i[
      name
      response
    ]
  PERSON_ATTRS = %i[
      first_name
      last_name
      usbc_id
      igbo_id
      birth_month
      birth_day
      nickname
      phone
      email
      address1
      address2
      city
      state
      country
      postal_code
    ].freeze
  BOWLER_ATTRS = [
    :position,
    :doubles_partner_num,
    :doubles_partner_identifier,
    :shift_identifier,
    person_attributes: PERSON_ATTRS,
    additional_question_responses: ADDITIONAL_QUESTION_RESPONSES_ATTRS,
  ].freeze

  ####################################

  def index
    permit_params
    load_tournament

    unless tournament.present?
      render json: nil, status: :not_found
      return
    end

    list = parameters[:unpartnered].present? ? tournament.bowlers.without_doubles_partner : tournament.bowlers
    render json: BowlerBlueprint.render(list, view: :list), status: :ok
  end

  def create
    permit_params
    load_team
    load_tournament

    # the tournament should be loaded either by association with the team, or finding by its identifier
    unless tournament.present?
      render json: nil, status: :not_found
      return
    end

    form_data = clean_up_bowler_data(parameters.require(:bowlers))
    bowlers = []
    form_data.each do |data|
      a_bowler = bowler_from_params(data)
      unless a_bowler.valid?
        Rails.logger.info(a_bowler.errors.inspect)
        render json: a_bowler.errors, status: :unprocessable_entity
        return
      end
      bowlers << a_bowler
    end

    registration_type = 'solo'

    # now, are they joining a team, or registering solo?
    if team.present?
      # joining
      if team.bowlers.count == tournament.team_size
        render json: { message: 'This team is full.' }, status: :bad_request
        return
      end
      registration_type = 'join_team'
    else
      # registering solo, doubles, or partner
      if bowlers.count == 2
        registration_type = 'new_pair'
      elsif bowlers.first.doubles_partner_id.present?
        registration_type = 'partner'
      end
    end

    bowlers.each do |b|
      b.save
      TournamentRegistration.register_bowler(b, registration_type)
    end

    if bowlers.count == 2
      bowlers[0].doubles_partner = bowlers[1]
      bowlers[1].doubles_partner = bowlers[0]
      bowlers.map(&:save)
    end

    render json: BowlerBlueprint.render(bowlers), status: :created
  end

  def show
    unless bowler.present?
      render json: nil, status: :not_found
      return
    end

    result = {
      bowler: BowlerBlueprint.render_as_hash(bowler, view: :detail),
      available_items: rendered_purchasable_items_by_identifier,
    }
    render json: result, status: :ok
  end

  class PurchaseError < RuntimeError
    attr_reader :http_status

    def initialize(msg, status)
      super(msg)
      @http_status = status
    end
  end

  # receive:
  # - bowler ID via params
  # - purchasable item IDs via request body
  # - unpaid purchase IDs via request body (return error if we think they're paid)
  # - expected total via request body (so we can proactively prevent purchase if we reach a different total,
  #  e.g., if they got the early discount upon registration but the date passed before they paid)
  #  ---- is that a thing we should enforce? survey directors to see what they think, add it later if they want it
  #
  #
  # return:
  #   - client ID (paypal identifier for tournament)
  #   - total to charge
  # def purchase_details
  #   unless bowler.present?
  #     render json: { error: 'Bowler not found' }, status: :not_found
  #     return
  #   end
  #
  #   # permit and parse params (quantities come in as strings)
  #   params.permit!
  #   details = params.to_h
  #
  #   process_purchase_details(details)
  #
  #   output = {
  #     total: total_to_charge,
  #     paypal_client_id: tournament.paypal_client_id,
  #   }
  #
  #   render json: output, status: :ok
  # rescue PurchaseError => e
  #   render json: { error: e.message }, status: e.http_status
  # end

  def stripe_checkout
    unless bowler.present?
      render json: { error: 'Bowler not found' }, status: :not_found
      return
    end

    load_stripe_account

    # permit and parse params (quantities come in as strings)
    params.permit!
    details = params.to_h

    process_purchase_details(details)

    session = {}
    if tournament.testing? && params[:simulate_failure].present?
      session[:id] = "pretend_checkout_session_#{bowler.id}_#{Time.zone.now.strftime('%FT%T')}"
      session[:url] = "/bowlers/#{bowler.identifier}/finish_checkout"
      bowler.stripe_checkout_sessions << StripeCheckoutSession.new(identifier: session[:id], status: :expired)
    elsif Rails.env.development? && tournament.config['skip_stripe'] || tournament.testing?
      finish_checkout_without_stripe
      session[:id] = "pretend_checkout_session_#{bowler.id}_#{Time.zone.now.strftime('%FT%T')}"
      session[:url] = "/bowlers/#{bowler.identifier}/finish_checkout"
      bowler.stripe_checkout_sessions << StripeCheckoutSession.new(identifier: session[:id], status: :completed)
    else
      # Now, we can build out the line items for the Stripe checkout session
      # matching_purchases -- all the unpaid purchases (entry fee, late fee, and early discount)
      # item_quantities -- an array of hashes, with identifier and quantity as keys
      # purchasable_items -- all the additional items being bought, indexed by identifier

      session = stripe_checkout_session
      bowler.stripe_checkout_sessions << StripeCheckoutSession.new(identifier: session[:id])
    end

    output = {
      redirect_to: session[:url],
      checkout_session_id: session[:id],
    }
    render json: output, status: :ok
  rescue PurchaseError => e
    render json: { error: e.message }, status: e.http_status
  end

  private

  attr_reader :team,
    :bowler,
    :parameters,
    :matching_purchases,
    :purchasable_items,
    :item_quantities,
    :total_to_charge

  def permit_params
    @parameters = params.permit(:identifier, :team_identifier, :tournament_identifier, :unpartnered, bowlers: BOWLER_ATTRS)
  end

  def load_bowler
    identifier = params.require(:identifier)
    @bowler = Bowler.includes(:tournament, :person, :ledger_entries, :team, { purchases: [:purchasable_item] })
                    .where(identifier: identifier)
                    .first
    @tournament = bowler&.tournament
    @team = bowler&.team
  end

  def load_team
    identifier = parameters[:team_identifier]
    if identifier.present?
      @team = Team.find_by_identifier(identifier)
      @tournament = team&.tournament
    end
  end

  def load_tournament
    return unless tournament.nil?
    identifier = parameters[:tournament_identifier]
    if identifier.present?
      @tournament = Tournament.includes(:bowlers, :stripe_account).find_by_identifier(identifier)
    end
  end

  def rendered_purchasable_items_by_identifier
    excluded_item_names = (bowler.purchases.single_use + bowler.purchases.event).collect { |p| p.purchasable_item.name }
    items = tournament.purchasable_items.user_selectable.where.not(name: excluded_item_names)
    items.each_with_object({}) { |i, result| result[i.identifier] = PurchasableItemBlueprint.render_as_hash(i) }
  end

  def clean_up_bowler_data(permitted_params)
    permitted_params.each do |p|
      # Remove any empty person attributes
      p['person_attributes'].delete_if { |_k, v| v.length.zero? }

      # Person attributes: Convert integer params from string to integer
      %w[birth_month birth_day].each do |attr|
        p['person_attributes'][attr] = p['person_attributes'][attr].to_i
      end

      # Remove additional question responses that are empty
      p['additional_question_responses'].filter! { |r| r['response'].present? }

      # transform the add'l question responses into the shape that we can accept via ActiveRecord
      p['additional_question_responses_attributes'] =
        additional_question_responses(p['additional_question_responses'])

      # remove that key from the params...
      p.delete('additional_question_responses')

      # If we've specified a doubles partner, then look them up by identifier and put their id in the params
      if p['doubles_partner_identifier'].present?
        partner = Bowler.where(identifier: p['doubles_partner_identifier'], doubles_partner_id: nil).first
        p['doubles_partner_id'] = partner.id unless partner.nil?
        p.delete('doubles_partner_identifier')
      end

      if p['shift_identifier'].present?
        shift = Shift.find_by(identifier: p['shift_identifier'])
        p['bowler_shift_attributes'] = { shift_id: shift.id } unless shift.nil?
        p.delete('shift_identifier')
      end
    end

    permitted_params
  end

  # These are used only when adding a bowler to an existing team

  def bowler_from_params(info)
    bowler = Bowler.new(info.merge(team: team, tournament: tournament))
    if team.present?
      partner = team.bowlers.without_doubles_partner.first
      bowler.doubles_partner = partner if partner.present?
    end
    bowler
  end

  def additional_question_responses(params)
    params.each_with_object([]) do |response_param, collected|
      collected << {
        response: response_param['response'],
        extended_form_field_id: extended_form_fields[response_param['name']].id,
      }
    end
  end

  def extended_form_fields
    @extended_form_fields ||= ExtendedFormField.all.index_by(&:name)
  end

  # in details:
  #
  # purchase_identifiers: [],
  # purchasable_items: [
  #   {
  #     identifier: ...,
  #     quantity: X,
  #   },
  #   ...
  # ],
  # expected_total:
  #
  # this method sets and populates the following class attributes:
  # - matching_purchases -- the unpaid purchases that have matching identifiers in details[purchase_identifiers]
  # - item_quantities -- an array of hashes, containing purchasable item identifiers and the quantity of each
  # - purchasable_items -- a collection of purchasable items, indexed by their identifiers
  #
  # Just a heads-up: discounts are included in these collections
  def process_purchase_details(details)
    details[:expected_total] = details[:expected_total].to_i
    details[:purchasable_items]&.each_index do |index|
      details[:purchasable_items][index][:quantity] = details[:purchasable_items][index][:quantity].to_i
    end

    # validate required ledger items (entry fee, early discount, late fee)
    purchase_identifiers = details[:purchase_identifiers] || []
    @matching_purchases = bowler.purchases.unpaid.where(identifier: purchase_identifiers)
    unless purchase_identifiers.count == matching_purchases.count
      raise PurchaseError.new('Mismatched unpaid purchases count', :precondition_failed)
    end
    purchases_total = matching_purchases.sum(&:amount)

    # gather purchasable items
    @item_quantities = details[:purchasable_items] || []
    identifiers = item_quantities.collect { |i| i[:identifier] }
    @purchasable_items = tournament.purchasable_items.where(identifier: identifiers).index_by(&:identifier)

    # does the number of items found match the number of identifiers passed in?
    unless identifiers.count == purchasable_items.count
      raise PurchaseError.new('Mismatched number of purchasable item identifiers', :not_found)
    end

    # are we purchasing any single-use item_quantities that have been purchased previously?
    matching_previous_single_item_purchases = PurchasableItem.single_use.joins(:purchases)
                                                             .where(identifier: identifiers)
                                                             .where(purchases: { bowler_id: bowler.id })
                                                             .where.not(purchases: { paid_at: nil })
    unless matching_previous_single_item_purchases.empty?
      raise PurchaseError.new('Attempting to purchase previously-purchased single-use item(s)', :precondition_failed)
    end

    # are we purchasing more than one of anything?
    multiples = item_quantities.filter { |i| i[:quantity] > 1 }
    # make sure they're all multi-use
    multiples.filter! do |i|
      identifier = i[:identifier]
      item = purchasable_items[identifier]
      !item.multi_use?
    end
    unless multiples.empty?
      raise PurchaseError.new('Cannot purchase multiple instances of single-use items.', :unprocessable_entity)
    end

    # apply any relevant event bundle discounts
    bundle_discount_items = tournament.purchasable_items.bundle_discount
    previous_paid_event_item_identifiers = bowler.purchases.event.paid.map { |p| p.purchasable_item.identifier }
    applicable_discounts = bundle_discount_items.select do |discount|
      (identifiers + previous_paid_event_item_identifiers).intersection(discount.configuration['events']).length == discount.configuration['events'].length
    end
    total_discount = applicable_discounts.sum(&:value)

    # apply any relevant event-linked late fees
    late_fee_items = tournament.purchasable_items.event_linked.late_fee
    applicable_fees = late_fee_items.select do |fee|
      identifiers.include?(fee.configuration['event']) && tournament.in_late_registration?(event_linked_late_fee: fee)
    end
    total_fees = applicable_fees.sum(&:value)

    # items_total = purchasable_items.sum(&:value)
    items_total = item_quantities.map do |item|
      identifier = item[:identifier]
      quantity = item[:quantity]
      purchasable_items[identifier].value * quantity
    end.sum

    # sum up the total of unpaid purchases and indicated purchasable items
    @total_to_charge = purchases_total + items_total + total_discount + total_fees

    # Disallow a purchase if there's nothing owed
    if total_to_charge == 0
      raise PurchaseError.new('Total to charge is zero', :precondition_failed)
    end
  end

  def stripe_checkout_session
    line_items = matching_purchases.each_with_object([]) do |mp, a|
      pi = mp.purchasable_item
      unless pi.early_discount? || pi.bundle_discount?
        a.push(line_item_for_purchasable_item(pi))
      end
    end

    line_items += item_quantities.collect do |iq|
      pi = purchasable_items[iq[:identifier]]
      line_item_for_purchasable_item(pi, iq[:quantity])
    end

    discounts = matching_purchases.each_with_object([]) do |mp, a|
      pi = mp.purchasable_item
      if pi.early_discount? || pi.bundle_discount?
        a.push(discount_for_purchasable_item(pi))
      end
    end

    session_params = {
      success_url: "#{client_host}/bowlers/#{bowler.identifier}/finish_checkout",
      cancel_url: "#{client_host}/bowlers/#{bowler.identifier}",
      line_items: line_items,
      mode: 'payment',
      customer_email: bowler.email,
      customer_creation: 'always',
      submit_type: 'pay',
    }

    session_params[:discounts] = discounts unless discounts.empty?
    create_stripe_checkout_session(session_params)
  end

  def create_stripe_checkout_session(session_params)
    Stripe::Checkout::Session.create(
      session_params,
      {
        stripe_account: stripe_account.identifier,
      },
    )
  rescue Stripe::StripeError => e
    Rails.logger.info "Stripe error: #{e}"
    Bugsnag.notify(e)
  end

  def finish_checkout_without_stripe
    total_credit = 0
    extp = ExternalPayment.create(
      details: {},
      identifier: "pretend_stripe_payment_#{Time.zone.now.strftime('%FT%T')}",
      payment_type: :stripe,
      tournament_id: tournament.id
    )

    # matching purchases (ledger items that are purchased but unpaid, including discounts)
    #  -- mark them as paid, create ledger entries
    matching_purchases.each do |mp|
      mp.update(
        paid_at: Time.zone.now,
        external_payment_id: extp.id
      )
      pi = mp.purchasable_item
      if pi.early_discount? || pi.bundle_discount?
        total_credit -= pi.value
      else
        total_credit += pi.value
      end
    end

    # new purchases, items, events, etc.
    #  -- create purchases and ledger entries, and mark them as paid
    item_quantities.each do |iq|
      pi = purchasable_items[iq[:identifier]]
      iq[:quantity].times do |_|
        bowler.purchases << Purchase.create(
          purchasable_item: pi,
          amount: pi.value,
          paid_at: Time.zone.now,
          external_payment_id: extp.id
        )

        bowler.ledger_entries << LedgerEntry.new(
          debit: pi.value,
          source: :purchase,
          identifier: pi.name
        )
        total_credit += pi.value
      end
    end

    bowler.ledger_entries << LedgerEntry.new(
      credit: total_credit,
      source: :stripe,
      identifier: 'pretend_stripe_payment',
    )
  end
end

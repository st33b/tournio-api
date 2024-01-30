module Director
  class LedgerEntriesController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.bowler = Bowler.includes(:tournament).find_by_identifier!(params[:bowler_identifier])

      authorize bowler, :update?

      entry = LedgerEntry.new(new_entry_params)
      entry.bowler = bowler
      entry.source = :manual
      entry.notes = "Created by #{current_user.email}"
      entry.save

      extp = ExternalPayment.create(
        payment_type: :manual,
        identifier: SecureRandom.uuid,
        details: entry.identifier,
        tournament: bowler.tournament
      )

      # Assume the payment is for the entry fee only, until we let directors specify what a manual payment is for
      # (The idea there is to allow arbitrary amounts, rather than assuming it's for the entry fee)
      if bowler.purchases.entry_fee.empty?
        entry_fee_item = bowler.tournament.purchasable_items.entry_fee.first
        bowler.purchases << Purchase.new(
          purchasable_item: entry_fee_item,
          amount: entry_fee_item.value,
          paid_at: Time.zone.now,
          external_payment_id: extp.id
        )
      end

      render json: LedgerEntryBlueprint.render(entry), status: :created
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    private

    attr_accessor :bowler, :ledger_entry

    def new_entry_params
      params.permit(:bowler_identifier, ledger_entry: [:credit, :identifier]).require(:ledger_entry)
    end
  end
end

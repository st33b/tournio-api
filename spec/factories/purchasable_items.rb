# == Schema Information
#
# Table name: purchasable_items
#
#  id              :bigint           not null, primary key
#  category        :string           not null
#  configuration   :jsonb
#  determination   :string
#  enabled         :boolean          default(TRUE)
#  identifier      :string           not null
#  name            :string           not null
#  refinement      :string
#  user_selectable :boolean          default(TRUE), not null
#  value           :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :bigint
#  tournament_id   :bigint
#
# Indexes
#
#  index_purchasable_items_on_tournament_id  (tournament_id)
#
FactoryBot.define do
  factory :purchasable_item do
    name { 'A purchasable item' }
    value { 50 }

    # association :stripe_product, strategy: :build
    # association :stripe_coupon, strategy: :build

    association :tournament, strategy: :create

    trait :entry_fee do
      category { :ledger }
      determination { :entry_fee }
      name { 'Entry fee' }
      value { 109 }
      user_selectable { false }
    end

    trait :late_fee do
      category { :ledger }
      determination { :late_fee }
      name { 'Late registration fee'}
      user_selectable { false }
      configuration do
        {
          applies_at: 2.weeks.ago,
        }
      end
    end

    trait :early_discount do
      category { :ledger }
      determination { :early_discount }
      name { 'Early registration discount' }
      value { 15 }
      user_selectable { false }
      configuration do
        {
          valid_until: 2.weeks.from_now,
        }
      end
    end

    # DEPRECATED in favor of voiding them
    trait :early_discount_expiration do
      category { :ledger }
      determination { :discount_expiration }
      name { 'Early-registration discount expiration' }
      user_selectable { false }
    end

    trait :scratch_competition do
      category { :bowling }
      determination { :single_use }
      refinement { :division }
      name { 'Scratch competition' }
      configuration do
        {
          division: 'A',
          note: 'Averages 209 and up',
          order: '',
        }
      end
    end

    trait :bowling_event do
      category { :bowling }
      determination { :event }
      refinement { :single }
      name { 'A fundamental event' }
      value { 100 }
      configuration do
        {
          order: 1,
        }
      end
    end

    trait :doubles_event do
      category { :bowling }
      determination { :event }
      refinement { :double }
      name { 'A fundamental doubles event' }
      value { 79 }
      configuration do
        {
          order: 1,
        }
      end
    end

    trait :optional_event do
      category { :bowling }
      determination { :single_use }
      name { 'An optional event' }
      configuration do
        {
          order: 1,
        }
      end
    end

    trait :banquet_entry do
      category { :banquet }
      name { 'Banquet entry for a non-bowler' }
    end

    trait :raffle_bundle do
      category { :raffle }
      name { 'Raffle ticket bundle' }
      configuration do
        {
          denomination: '100 tickets',
          order: 1,
        }
      end
    end

    trait :event_bundle_discount do
      category { :ledger }
      determination { :bundle_discount }
      name { 'Event Bundle' }
      value { -20 }
      after(:create) do |pi, _|
        create :stripe_coupon, purchasable_item: pi
        e1 = create :purchasable_item, :bowling_event, :with_stripe_product, tournament: pi.tournament
        e2 = create :purchasable_item, :bowling_event, :with_stripe_product, tournament: pi.tournament
        pi.configuration['events'] = [e1.identifier, e2.identifier]
        pi.save
      end
    end

    trait :event_late_fee do
      category { :ledger }
      determination { :late_fee }
      refinement { :event_linked }
      name { 'Late registration fee for an event'}
      user_selectable { false }
      value { 15 }
      configuration do
        {
          applies_at: 2.weeks.from_now,
        }
      end
      after(:create) do |pi, _|
        e = create :purchasable_item, :bowling_event, tournament: pi.tournament
        pi.configuration['event'] = e.identifier
        pi.save
      end
    end

    trait :with_stripe_product do
      after(:create) do |pi, _|
        create :stripe_product, purchasable_item: pi
      end
    end

    trait :with_stripe_coupon do
      after(:create) do |pi, _|
        create :stripe_coupon, purchasable_item: pi
      end
    end

    trait :sanction do
      category { :sanction }
      determination { :igbo }
      name { 'IGBO Membership' }
      value { 27 }
    end

    trait :apparel do
      category { :product }
      determination { :apparel }
      name { 'An item of clothing for everyone' }
    end

    trait :one_size_fits_all do
      configuration do
        {
          note: 'An interesting tidbit',
          size: 'one_size_fits_all',
        }
      end
    end

    trait :sized do
      refinement { :sized }
      configuration do
        {
          sizes: {
            unisex: {
              s: true,
              m: true,
              l: true,
            },
          },
        }
      end
      after(:create) do |pi, _|
        size_strings = []
        pi.configuration['sizes'].each_pair do |group, sizes|
          sizes.each_key { |size| size_strings << ApparelDetails.serialize_size(group, size) }
        end
        size_strings.each do |str|
          kid = create :purchasable_item, :apparel, tournament: pi.tournament, parent: pi, name: pi.name, configuration: { size: str, parent_identifier: pi.identifier }
          create :stripe_product, purchasable_item: kid
        end
      end
    end

    trait :disabled do
      enabled { false }
    end
  end
end

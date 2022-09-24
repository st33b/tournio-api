# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'San Francisco Golden Gate Classic',
  year: 2023,
  start_date: '2023-02-17',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'San Francisco, CA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2023-02-11T23:59:59-08:00',
  ),
  ConfigItem.new(
    key: 'timezone',
    value: 'America/Los_Angeles',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.goldengateclassic.org',
  ),
  ConfigItem.new(
    key: 'email_in_dev',
    value: 'false',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
]

tournament.contacts << Contact.new(
  name: 'Kylie Minogue',
  email: 'director@tournament.org',
  notes: 'Purser',
)
tournament.contacts << Contact.new(
  name: 'Dua Lipa',
  email: 'architect@tournament.org',
  notes: 'Architect',
)
tournament.contacts << Contact.new(
  name: 'Judy Garland',
  email: 'judy@tournament.org',
  notes: 'Musical Director',
)



# tournament.purchasable_items += [
#   PurchasableItem.new(
#     category: :ledger,
#     determination: :entry_fee,
#     name: 'Tournament entry fee',
#     user_selectable: false,
#     value: 109,
#   ),
#   PurchasableItem.new(
#     category: :ledger,
#     determination: :early_discount,
#     name: 'Early registration discount',
#     user_selectable: false,
#     value: -10,
#     configuration: {
#       valid_until: '2023-01-03T00:00:00-08:00',
#     },
#   ),
#   PurchasableItem.new(
#     category: :ledger,
#     determination: :late_fee,
#     name: 'Late registration fee',
#     user_selectable: false,
#     value: 10,
#     configuration: {
#       applies_at: '2023-02-01T00:00:00-08:00',
#     },
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Thursday night 9-pin No-tap',
#     user_selectable: true,
#     value: 25,
#     configuration: {
#       order: 1,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Optional Scratch',
#     user_selectable: true,
#     value: 20,
#     configuration: {
#       order: 3,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Optional Handicap',
#     user_selectable: true,
#     value: 20,
#     configuration: {
#       order: 4,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Scratch Side Pots',
#     user_selectable: true,
#     value: 30,
#     configuration: {
#       order: 5,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Handicap Side Pots',
#     user_selectable: true,
#     value: 30,
#     configuration: {
#       order: 6,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Mystery Doubles',
#     user_selectable: true,
#     value: 10,
#     configuration: {
#       order: 7,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     name: 'Best 3 Across 9',
#     user_selectable: true,
#     value: 20,
#     configuration: {
#       order: 8,
#     }
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     refinement: :division,
#     name: 'Scratch Masters',
#     user_selectable: true,
#     value: 50,
#     configuration: {
#       division: 'E',
#       note: '0-149',
#     },
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     refinement: :division,
#     name: 'Scratch Masters',
#     user_selectable: true,
#     value: 50,
#     configuration: {
#       division: 'D',
#       note: '150-169',
#     },
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     refinement: :division,
#     name: 'Scratch Masters',
#     user_selectable: true,
#     value: 50,
#     configuration: {
#       division: 'C',
#       note: '170-189',
#     },
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     refinement: :division,
#     name: 'Scratch Masters',
#     user_selectable: true,
#     value: 60,
#     configuration: {
#       division: 'B',
#       note: '190-208',
#     },
#   ),
#   PurchasableItem.new(
#     category: :bowling,
#     determination: :single_use,
#     refinement: :division,
#     name: 'Scratch Masters',
#     user_selectable: true,
#     value: 60,
#     configuration: {
#       division: 'A',
#       note: '209+',
#     },
#   ),
#   PurchasableItem.new(
#     category: :banquet,
#     determination: :multi_use,
#     name: 'Banquet Entry (non-bowler)',
#     user_selectable: true,
#     value: 40,
#   ),
# ]

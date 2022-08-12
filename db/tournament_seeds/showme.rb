# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Show Me St. Louis Classic',
  year: 2022,
  start_date: '2022-09-02',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'St. Louis, MO',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-08-24T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Chicago',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'https://showmeclassic.com/',
  ),
  ConfigItem.new(
    key: 'paypal_client_id',
    value: 'sb',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
]

if (Rails.env.development?)
  tournament.config_items << ConfigItem.new(key: 'email_in_dev', value: 'false')
end

# tournament.contacts << Contact.new(
#   name: 'Rich Bax',
#   email: 'richardjbax@yahoo.com',
#   role: :director,
# )
tournament.contacts << Contact.new(
  name: 'Rich Hagan',
  email: 'stlnutsy1@aol.com',
  role: :director,
)
# tournament.contacts << Contact.new(
#   name: 'Stephen Bodine',
#   email: 'stlouisguy99@sbcglobal.net',
#   role: :secretary,
# )
tournament.contacts << Contact.new(
  name: 'Del Watlington',
  email: 'msnlsec@yahoo.com',
  role: :registration,
  notify_on_registration: true,
  notification_preference: :daily_summary,
)
tournament.contacts << Contact.new(
  name: 'Jennifer Herbert',
  email: 'jennifer@adcreations.com',
  role: :treasurer,
  notify_on_payment: true,
  notification_preference: :daily_summary,
)

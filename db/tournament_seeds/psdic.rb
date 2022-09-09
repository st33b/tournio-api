# frozen_string_literal: true

psdic = Tournament.create!(
  name: 'Palm Springs Desert Invitational Classic',
  year: 2023,
  start_date: '2023-10-20',
)

psdic.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Palm Springs, CA',
  ),
  ConfigItem.new(
    key: 'late_fee_applies_at',
    value: '2023-09-12T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2023-10-12T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Los_Angeles',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://psdic.org/home/',
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

psdic.contacts += [
  Contact.new(
    name: 'PSDIC Director',
    email: 'psdic-director@igbo-reg.com',
    notes: 'Director',
  ),
  Contact.new(
    name: 'Secretary',
    email: 'psdic-secretary@igbo-reg.com',
    notes: 'Secretary',
  ),
  Contact.new(
    name: 'Treasurer',
    email: 'psdic-moneys@igbo-reg.com',
    notes: 'Treasurer',
  ),
  Contact.new(
    name: 'IGBO Representative',
    email: 'psdic-igbo@igbo-reg.com',
    notes: 'IGBO Rep',
  ),
]

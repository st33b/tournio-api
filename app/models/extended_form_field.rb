# == Schema Information
#
# Table name: extended_form_fields
#
#  id                  :bigint           not null, primary key
#  helper_text         :string
#  helper_url          :string
#  html_element_config :jsonb
#  html_element_type   :string           default("input")
#  label               :string           not null
#  name                :string           not null
#  validation_rules    :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class ExtendedFormField < ApplicationRecord
  validates :name, format: { with: /\A[a-zA-Z0-9]+\z/, message: 'must be camelCased and alphanumeric only (e.g., no spaces, hyphens, or underscores)' }
end

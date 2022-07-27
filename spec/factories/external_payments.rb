# == Schema Information
#
# Table name: external_payments
#
#  id           :bigint           not null, primary key
#  details      :jsonb
#  identifier   :string
#  payment_type :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_external_payments_on_identifier  (identifier)
#
FactoryBot.define do

  # enum :payment_type, %i(paypal stripe)

  factory :external_payment do
    trait :from_paypal do
      identifier { "paypal_payment_#{SecureRandom.uuid}"}
      payment_type { :paypal }
    end

    trait :from_stripe do
      identifier { "stripe_payment_#{SecureRandom.uuid}"}
      payment_type { :stripe }
    end
  end
end

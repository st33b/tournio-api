# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  confirmed     :integer          default(0), not null
#  description   :string
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string
#  requested     :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_identifier     (identifier) UNIQUE
#  index_shifts_on_tournament_id  (tournament_id)
#
class Shift < ApplicationRecord
  belongs_to :tournament

  has_many :bowler_shifts, dependent: :destroy
  has_many :bowlers, through: :bowler_shifts

  validates :capacity, comparison: { greater_than_or_equal_to: :confirmed }

  scope :available, -> { where('confirmed < capacity') }

  before_create :generate_identifier, if: -> { identifier.blank? }

  def to_param
    identifier
  end

  def reset_counts
    update(confirmed: 0, requested: 0)
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end

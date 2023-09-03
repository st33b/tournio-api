# frozen_string_literal: true
#
# == Schema Information
#
# Table name: teams
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  initial_size  :integer          default(4)
#  name          :string
#  options       :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  shift_id      :bigint
#  tournament_id :bigint
#
# Indexes
#
#  index_teams_on_identifier     (identifier) UNIQUE
#  index_teams_on_shift_id       (shift_id)
#  index_teams_on_tournament_id  (tournament_id)
#

class TeamSerializer
  include Alba::Resource

  transform_keys :lower_camel

  # root_key :team

  attributes :identifier, :name, :initial_size, :created_at

  # one :tournament, resource: TournamentSerializer
  one :shift, resource: ShiftSerializer
end

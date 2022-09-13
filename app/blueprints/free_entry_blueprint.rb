# frozen_string_literal: true

class FreeEntryBlueprint < Blueprinter::Base
  identifier :identifier
  fields :id, :unique_code, :confirmed

  view :director_list do
    association :bowler, blueprint: BowlerBlueprint
  end
end

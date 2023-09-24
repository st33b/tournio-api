# frozen_string_literal: true

# == Schema Information
#
# Table name: tournaments
#
#  id                :bigint           not null, primary key
#  aasm_state        :string           not null
#  abbreviation      :string
#  details           :jsonb
#  end_date          :date
#  entry_deadline    :datetime
#  identifier        :string           not null
#  location          :string
#  name              :string           not null
#  start_date        :date
#  timezone          :string           default("America/New_York")
#  year              :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  tournament_org_id :bigint
#
# Indexes
#
#  index_tournaments_on_aasm_state         (aasm_state)
#  index_tournaments_on_identifier         (identifier)
#  index_tournaments_on_tournament_org_id  (tournament_org_id)
#

require 'rails_helper'

RSpec.describe Tournament, type: :model do
  let(:tournament) { create(:tournament) }

  describe 'creation callbacks' do
    subject { tournament.save }

    context 'on a new tournament' do
      let(:tournament) { build(:tournament) }

      it 'generates an identifier upon initial save' do
        expect { subject }.to change(tournament, :identifier).from(nil).to(anything)
      end
    end

    context 'on an existing tournament' do
      it 'does not change the identifier, even if the name or year have changed' do
        tournament.year = tournament.year + 1
        expect { subject }.not_to change(tournament, :identifier)
      end
    end
  end

  describe 'state changes' do
    it 'starts in setup mode' do
      expect(tournament.setup?).to be_truthy
      expect(tournament.testing?).to be_falsey
      expect(tournament.active?).to be_falsey
      expect(tournament.closed?).to be_falsey
      expect(tournament.demo?).to be_falsey
    end

    context 'in setup mode' do
      it 'is not in the "active" scope' do
        expect(described_class.active).not_to include(tournament)
      end

      it 'permits transition to testing' do
        expect { tournament.test! }.not_to raise_error
      end

      it 'permits transition to demo' do
        expect { tournament.demonstrate! }.not_to raise_error
      end

      it 'forbids the reset event' do
        expect { tournament.reset! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to open' do
        expect { tournament.open! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to closed' do
        expect { tournament.close! }.to raise_error(AASM::InvalidTransition)
      end
    end

    context 'in test mode' do
      let(:tournament) { create(:tournament, :testing) }

      it 'is not in the "active" scope' do
        expect(described_class.active).not_to include(tournament)
      end

      it 'forbids transition to testing' do
        expect { tournament.test! }.to raise_error(AASM::InvalidTransition)
      end

      it 'permits transition to open' do
        expect { tournament.open! }.not_to raise_error
      end

      it 'forbids transition to closed' do
        expect { tournament.close! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to demo' do
        expect { tournament.demonstrate! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids the reset event' do
        expect { tournament.reset! }.to raise_error(AASM::InvalidTransition)
      end
    end

    context 'in active mode' do
      let(:tournament) { create(:tournament, :active) }

      it 'is in the "active" scope' do
        expect(described_class.active).to include(tournament)
      end

      it 'forbids transition to testing' do
        expect { tournament.test! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to open' do
        expect { tournament.open! }.to raise_error(AASM::InvalidTransition)
      end

      it 'permits transition to closed' do
        expect { tournament.close! }.not_to raise_error
      end

      it 'forbids transition to demo' do
        expect { tournament.demonstrate! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids the reset event' do
        expect { tournament.reset! }.to raise_error(AASM::InvalidTransition)
      end
    end

    context 'in closed mode' do
      let(:tournament) { create(:tournament, :closed) }

      it 'is not in the "active" scope' do
        expect(described_class.active).not_to include(tournament)
      end

      it 'forbids transition to testing' do
        expect { tournament.test! }.to raise_error(AASM::InvalidTransition)
      end

      it 'permits transition to open' do
        expect { tournament.open! }.not_to raise_error
      end

      it 'forbids transition to closed' do
        expect { tournament.close! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to demo' do
        expect { tournament.demonstrate! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids the reset event' do
        expect { tournament.reset! }.to raise_error(AASM::InvalidTransition)
      end
    end

    context 'in the demo state' do
      let(:tournament) { create(:tournament, :demo) }

      it 'is not in the "active" scope' do
        expect(described_class.active).not_to include(tournament)
      end

      it 'forbids transition to testing' do
        expect { tournament.test! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to open' do
        expect { tournament.open! }.to raise_error(AASM::InvalidTransition)
      end

      it 'forbids transition to closed' do
        expect { tournament.close! }.to raise_error(AASM::InvalidTransition)
      end

      it 'permits the reset event' do
        expect { tournament.reset! }.not_to raise_error
      end
    end

  end
end

require 'rails_helper'

describe TeamsController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#create' do
    subject { post uri, params: new_team_params, as: :json }

    let(:uri) { "/tournaments/#{tournament.identifier}/teams" }
    let(:tournament) { create :tournament, :active, :with_entry_fee, :one_shift }
    let!(:shift) { create :shift, :high_demand, tournament: tournament, identifier: 'this-is-a-shift' }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    context 'with a full team' do
      let(:new_team_params) do
        {
          team: full_team_test_data,
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'creates a BowlerShift instance for each member of the team' do
        expect { subject }.to change(BowlerShift, :count).by(4)
      end

      it 'bumps the requested count of the specified shift' do
        expect { subject }.to change { shift.reload.requested }.by(4)
      end

      it 'does not bump the confirmed count' do
        expect { subject }.not_to change { shift.reload.confirmed }
      end

      it 'does not set the place_with_others attribute under options' do
        subject
        team = Team.last
        expect(team.options['place_with_others']).to be_nil
      end

      it 'correctly pairs up the doubles pairs' do
        subject
        team = Team.last
        team.bowlers.each do |me|
          you = Bowler.find(me.doubles_partner_id)

          expect(you.doubles_partner_id).to eq(me.id)
        end
      end

      it 'includes the new team in the response' do
        subject
        expect(json).to have_key('name')
        expect(json).to have_key('identifier')
        expect(json).to have_key('bowlers')
        expect(json['name']).to eq(full_team_test_data['name'])
      end

      it 'creates data points' do
        expect { subject }.to change(DataPoint, :count).by(4)
      end

      it 'creates the right kinds of data points' do
        subject
        dp = DataPoint.last(4)
        keys = dp.collect(&:key).uniq
        values = dp.collect(&:value).uniq
        expect(keys).to match_array(%w(registration_type))
        expect(values).to match_array(%w(new_team))
      end

      it 'associates the data points with the tournament' do
        subject
        dp = DataPoint.last(4)
        tournament_ids = dp.collect(&:tournament_id).uniq
        expect(tournament_ids).to match_array([tournament.id])
      end

      context 'somehow with no shift identifier' do
        let(:new_team_params) do
          {
            team: full_team_test_data_missing_shift,
          }
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'creates a BowlerShift instance for each member of the team' do
          expect { subject }.to change(BowlerShift, :count).by(4)
        end

        it "bumps the requested count of the tournament's only shift" do
          expect { subject }.to change { tournament.shifts.first.requested }
        end
      end
    end

    context 'with one bowler and an initial size of 3' do
      let(:new_team_params) do
        {
          team: partial_team_test_data.merge(
            'initial_size' => 3,
            'shift_identifier' => shift.identifier,
          ),
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'includes the new team in the response' do
        subject
        expect(json).to have_key('name')
        expect(json).to have_key('identifier')
        expect(json).to have_key('bowlers')
        expect(json['name']).to eq(partial_team_test_data['name'])
        expect(json['initial_size']).to eq(3)
      end

      it 'creates the right kinds of data point' do
        subject
        dp = DataPoint.last
        expect(dp.key).to eq('registration_type')
        expect(dp.value).to eq('new_team')
      end

    end

    context 'supporting placeholders' do
      # expectation is for a single bowler to come through, but we might be able to support more.
      before do
        create :shift, tournament: tournament, identifier: single_bowler_team_test_data['shift_identifier']
      end

      let(:new_team_params) do
        {
          team: single_bowler_team_test_data,
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'includes the new team in the response' do
        subject
        expect(json).to have_key('name')
        expect(json).to have_key('identifier')
        expect(json).to have_key('bowlers')
        expect(json['name']).to eq(single_bowler_team_test_data['name'])
        expect(json['initial_size']).to eq(single_bowler_team_test_data['initial_size'].to_i)
      end

      it 'associates the team to the specified shift' do
        subject
        expect(Team.last.shift.identifier).to eq(single_bowler_team_test_data['shift_identifier'])
      end
    end

    context 'with invalid data' do
      let(:new_team_params) do
        {
          team: invalid_team_test_data,
        }
      end

      it 'fails' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '#index' do
    subject { get uri, headers: headers, as: :json }

    let(:uri) { "/tournaments/#{tournament.identifier}/teams" }
    let(:tournament) { create :tournament, :active, :one_shift }
    let(:expected_keys) { %w(identifier name size) }

    before do
      create :team, :standard_one_bowler, tournament: tournament
      create :team, :standard_one_bowler, tournament: tournament
      create :team, :standard_two_bowlers, tournament: tournament
      create :team, :standard_two_bowlers, tournament: tournament
      create :team, :standard_three_bowlers, tournament: tournament
      create :team, :standard_three_bowlers, tournament: tournament
      create :team, :standard_three_bowlers, tournament: tournament
      create :team, :standard_full_team, tournament: tournament
      create :team, :standard_full_team, tournament: tournament
      create :team, :standard_full_team, tournament: tournament
    end

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all teams' do
      subject
      expect(json.count).to eq(10)
    end
  end

  describe '#show' do
    subject { get uri, headers: headers, as: :json }

    let(:uri) { "/teams/#{team.identifier}" }
    let(:tournament) { create :tournament, :active, :one_shift }
    let!(:team) { create :team, :standard_full_team, tournament: tournament }
    let(:expected_keys) { %w(identifier name size bowlers) }

    it 'succeeds' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'includes a team in the body' do
      subject
      expect(json).not_to be_nil
    end

    it 'returns the expected identifier in the body' do
      subject
      expect(json['identifier']).to eq(team.identifier)
    end

    it 'returns the expected name in the body' do
      subject
      expect(json['name']).to eq(team.name)
    end

    it 'returns the expected bowlers in the body' do
      subject
      expect(json['bowlers'].count).to eq(team.bowlers.count)
    end

    context 'a team that does not exist' do
      let (:uri) { '/teams/some-other-identifier'}

      it 'fails with a 404' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

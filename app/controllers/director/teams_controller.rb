# frozen_string_literal: true

module Director
  class TeamsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def index
      load_tournament
      unless @tournament.present?
        skip_policy_scope
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?
      teams = if (params[:partial])
                policy_scope(tournament.available_to_join)
              else
                policy_scope(tournament.teams).order('created_at asc')
              end
      render json: TeamBlueprint.render(teams, view: :director_list), status: :ok
    end

    def show
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?
      render json: TeamBlueprint.render(team, view: :director_detail)
    end

    def create
      load_tournament
      unless tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      new_team_params = { tournament: tournament }.merge(team_params)
      team = Team.new(new_team_params)
      unless team.valid?
        render json: nil, status: :bad_request
        return
      end

      team.save
      render json: TeamBlueprint.render(team, view: :director_list), status: :created
    end

    class InsufficientCapacityError < ::StandardError
    end

    def update
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament
      new_values = edit_team_params

      if new_values['shift_identifier'].present?
        # This isn't a normal RESTful request.
        handle_shift_change new_values['shift_identifier']
      else
        unless positions_valid?(new_values)
          render json: { errors: ['Positions must be unique across the team'] }, status: :bad_request
          return
        end

        unless team.update(new_values)
          render json: { errors: team.errors.full_messages }, status: :bad_request
          return
        end
      end

      render json: TeamBlueprint.render(team.reload, view: :director_detail), status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: nil, status: :not_found
    rescue InsufficientCapacityError => e
      render json: { error: 'Insufficient space remaining' }, status: :conflict
    end

    def destroy
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      unless team.destroy
        render json: nil, status: :bad_request
        return
      end

      render json: nil, status: :no_content
    end

    private

    attr_accessor :tournament, :team

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.includes(:teams).find_by_identifier(id)
    end

    def load_team_and_tournament
      id = params.require(:identifier)
      @team = Team.includes(:tournament, bowlers: [:person, :free_entry]).find_by(identifier: id)
      @tournament = team.tournament if team.present?
    end

    def team_params
      params.require(:team).permit(:name).to_h.symbolize_keys
    end

    def edit_team_params
      params.require(:team).permit(
        :name,
        :shift_identifier,
        bowlers_attributes: %i[id position doubles_partner_id],
      ).to_h.with_indifferent_access
    end

    def positions_valid?(proposed_values)
      positions = proposed_values[:bowlers_attributes].collect { |attrs| attrs[:position] }
      positions.count == positions.uniq.count
    end

    def handle_shift_change(new_shift_identifier)
      new_shift = Shift.find_by!(identifier: new_shift_identifier)
      if new_shift.confirmed + team.bowlers.count > new_shift.capacity
        raise InsufficientCapacityError
      end
      team.bowlers.each do |bowler|
        bowler.bowler_shift.destroy
        bowler.bowler_shift = BowlerShift.new(shift: new_shift)
        TournamentRegistration.try_confirming_bowler_shift(bowler)
      end
    end
  end
end

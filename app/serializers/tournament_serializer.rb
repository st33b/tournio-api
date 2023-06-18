# frozen_string_literal: true

class TournamentSerializer
  include Alba::Resource

  transform_keys :lower_camel

  root_key :tournament

  attributes :identifier, :name, :year, :abbreviation, :start_date, :end_date, :location, :timezone,:team_size

  # Seems silly to use a block for this, but oh well. Implementation via DSL would wind up
  # doing the same thing, I suppose.
  attribute :state do |t|
    t.aasm_state
  end

  attribute :image_url do |t|
    if params[:host].present? && t.logo_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(t.logo_image, params)
    end
  end

  attribute :entry_deadline do |t|
    t.entry_deadline.strftime('%FT%R%:z')
  end

  attribute :config do |t|
    %i(display_capacity publicly_listed email_in_dev website).each_with_object({}) do |key, hash|
      hash[key] = t.config[key]
    end
  end
end

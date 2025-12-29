# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Venue Metrics', type: :request do
  let(:locale) { I18n.default_locale }
  let!(:venue) { create(:venue, :public) }

  before do
    # Configure host platform
    create(:better_together_platform, :host, privacy: 'public')
    wizard = BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup')
    wizard.mark_completed
  end

  describe 'Page view tracking API' do
    # rubocop:todo RSpec/MultipleExpectations
    it 'enqueues a track page view job when posting to page views endpoint' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      # rubocop:enable RSpec/MultipleExpectations
      expect do
        post better_together.metrics_page_views_path(locale:),
             params: {
               viewable_type: 'Venue',
               viewable_id: venue.id,
               locale: locale.to_s
             },
             as: :json
      end.to have_enqueued_job(BetterTogether::Metrics::TrackPageViewJob).with(venue, locale.to_s)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end
  end
end

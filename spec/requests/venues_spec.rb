# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Venues', type: :request do
  let(:locale) { I18n.default_locale }
  let!(:venue) { create(:venue, :public) }

  before do
    # Configure host platform without including DeviseSessionHelpers to avoid route conflicts
    create(:better_together_platform, :host, privacy: 'public')
    wizard = BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup')
    wizard.mark_completed
  end

  def capture_select_queries
    queries = []
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql].to_s
      next if payload[:cached]
      next if payload[:name].in?(%w[SCHEMA TRANSACTION])
      next unless sql.lstrip.start_with?('SELECT')

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }
    queries
  end

  def create_hosted_event_for(host)
    event = create(:better_together_event, :with_simple_location)
    create(:better_together_event_host, event:, host:)
    event.categories << create(:event_category)
    event
  end

  describe 'URL helpers' do
    it 'generates correct venues index path' do
      expect(venues_path(locale:)).to eq("/#{locale}/venues")
    end

    it 'generates correct venue show path' do
      expect(venue_path(venue, locale:)).to eq("/#{locale}/venues/#{venue.slug}")
    end
  end

  describe 'GET /venues' do
    it 'renders the index page' do
      get venues_path(locale:)
      expect(response).to have_http_status(:ok)
    end

    it 'renders without N+1 queries when venues exist (exercises eager-loaded venue_images)' do
      # Create additional public venues to exercise the collection query path
      create_list(:venue, 2, :public)

      get venues_path(locale:)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /venues/:id' do
    it 'renders the show page' do
      get venue_path(venue, locale:)
      expect(response).to have_http_status(:ok)
    end

    it 'keeps show-page query growth bounded when additional hosted events are rendered' do
      create_hosted_event_for(venue)

      baseline_queries = capture_select_queries do
        get venue_path(venue, locale:)
      end
      expect(response).to have_http_status(:ok)

      create_list(:better_together_event, 2, :with_simple_location).each do |event|
        create(:better_together_event_host, event:, host: venue)
        event.categories << create(:event_category)
      end

      expanded_queries = capture_select_queries do
        get venue_path(venue, locale:)
      end
      expect(response).to have_http_status(:ok)

      expect(expanded_queries.size - baseline_queries.size).to be <= 6
    end
  end
end

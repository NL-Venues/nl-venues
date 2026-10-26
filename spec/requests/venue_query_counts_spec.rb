# frozen_string_literal: true

require 'rails_helper'

# Guards the venue pages against per-record queries: the page makes the same number of
# queries (give or take a few) however many venues, images, stages, offers or events it shows.
# rubocop:disable-next RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe 'Venue page query counts', type: :request do
  let(:locale) { I18n.default_locale }

  before do
    host = BetterTogether::Platform.find_by(host: true) || create(:better_together_platform, :host, privacy: 'public')
    host.community&.update_columns(privacy: 'public')
    host.update_columns(privacy: 'public')
    BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup').mark_completed
  end

  def select_queries(&)
    queries = []
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql].to_s
      next if payload[:cached] || payload[:name].in?(%w[SCHEMA TRANSACTION]) || !sql.lstrip.start_with?('SELECT')

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    queries
  end

  def add_details_to(venue, count)
    count.times do
      create(:stage, venue:)
      create(:venue_building, venue:)
      create(:venue_image, venue:, image: create(:better_together_content_image, privacy: 'public'))
      event = create(:better_together_event, :with_simple_location)
      create(:better_together_event_host, event:, host: venue)
      event.categories << create(:event_category)
    end
  end

  describe 'GET /venues' do
    it 'does not query per venue' do
      create_list(:venue, 2, :public).each { |venue| add_details_to(venue, 1) }
      few = select_queries { get venues_path(locale:) }

      create_list(:venue, 6, :public).each { |venue| add_details_to(venue, 1) }
      many = select_queries { get venues_path(locale:) }

      expect(response).to have_http_status(:ok)
      expect(many.size - few.size).to be <= 10
    end
  end

  describe 'GET /venues/:id' do
    it 'does not query per image, stage, building or hosted event' do
      venue = create(:venue, :public)
      add_details_to(venue, 1)
      few = select_queries { get venue_path(venue, locale:) }
      expect(response).to have_http_status(:ok)

      add_details_to(venue, 4)
      many = select_queries { get venue_path(venue.reload, locale:) }

      expect(response).to have_http_status(:ok)
      expect(many.size - few.size).to be <= 12
    end

    it 'still shows every hosted event' do
      venue = create(:venue, :public)
      add_details_to(venue, 3)

      get venue_path(venue, locale:)

      expect(venue.hosted_events.map(&:name)).to all(satisfy { |name| response.body.include?(ERB::Util.h(name)) })
    end
  end
end

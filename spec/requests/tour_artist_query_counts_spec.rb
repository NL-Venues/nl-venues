# frozen_string_literal: true

require 'rails_helper'

# Guards the tour and artist pages against per-record queries. Each page may still cost one query
# per record for the card title, so the allowance is below the two or more per record they cost before.
# rubocop:disable-next RSpec/ExampleLength
RSpec.describe 'Tour and artist page query counts', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:locale) { I18n.default_locale }

  before do
    host = BetterTogether::Platform.find_by(host: true) || create(:better_together_platform, :host, privacy: 'public')
    host.community&.update_columns(privacy: 'public')
    host.update_columns(privacy: 'public')
    BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup').mark_completed
  end

  # rubocop:disable-next Metrics/AbcSize
  def select_queries(path)
    sign_in create(:nl_venues_user, :confirmed, :platform_manager)
    queries = []
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql].to_s
      next if payload[:cached] || payload[:name].in?(%w[SCHEMA TRANSACTION]) || !sql.lstrip.start_with?('SELECT')

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { get path }
    expect(response).to have_http_status(:ok)
    queries.size
  end

  def create_artists(count)
    Array.new(count) { Artist.create!(name: "Artist #{SecureRandom.hex(3)}", privacy: 'public') }
  end

  def create_tour
    Tour.create!(name: "Tour #{SecureRandom.hex(3)}", privacy: 'public', starts_at: 1.week.from_now)
  end

  it 'does not query per artist on the artists index' do
    create_artists(2)
    few = select_queries(artists_path(locale:))
    create_artists(8)

    expect(select_queries(artists_path(locale:)) - few).to be <= 10
  end

  it 'does not query per tour on the tours index' do
    2.times { create_tour }
    few = select_queries(tours_path(locale:))
    8.times { create_tour }

    expect(select_queries(tours_path(locale:)) - few).to be <= 10
  end

  it 'does not query per stop or artist on the tour page' do
    tour = create_tour
    add = lambda do |count|
      count.times do
        TourStop.create!(tour:, venue: create(:venue, :public))
        TourArtist.create!(tour:, artist: create_artists(1).first)
      end
    end
    add.call(2)
    few = select_queries(tour_path(tour, locale:))
    add.call(8)

    expect(select_queries(tour_path(tour.reload, locale:)) - few).to be <= 22
  end
end

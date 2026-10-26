# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable-next RSpec/ExampleLength
RSpec.describe VenueCollectionMap do
  include DeviseSessionHelpers

  before { configure_host_platform }

  def venue_with_geocoded_building(name:, privacy: 'public', line1: '1 Water St', latitude: 48.95, longitude: -57.95)
    venue = create(:venue, name:, privacy:)
    address = build(:better_together_address, line1:, city_name: 'Corner Brook', country_name: 'Canada',
                                              privacy: 'public', primary_flag: true)
    building = create(:better_together_infrastructure_building, address:, privacy: 'public')
    create(:venue_building, venue:, building:)
    building.geospatial_space.space.assign_attributes(latitude:, longitude:)
    building.geospatial_space.save!
    venue.reload
  end

  def query_count(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  describe '#leaflet_points and #spaces' do
    it 'returns one point per geocoded venue building, each linking to the venue', :aggregate_failures do
      venue = venue_with_geocoded_building(name: 'Harbour Hall')

      points = described_class.new.leaflet_points

      expect(points.size).to eq(1)
      expect(points.first).to include(lat: 48.95, lng: -57.95)
      expect(points.first[:popup_html]).to include("/venues/#{venue.slug}", 'Harbour Hall')
      expect(described_class.new.spaces.size).to eq(1)
    end

    it 'escapes the venue name and address in popup markup', :aggregate_failures do
      venue_with_geocoded_building(name: '<img src=x onerror=alert(1)> Hall', line1: '<b>1 Main</b>')

      popup = described_class.new.leaflet_points.first[:popup_html]

      expect(popup).to include('&lt;img src=x onerror=alert(1)&gt; Hall')
      expect(popup).not_to include('<img')
      expect(popup).not_to include('<b>1 Main')
    end

    it 'skips venues whose buildings are not geocoded' do
      venue = create(:venue)
      create(:venue_building, venue:)

      expect(described_class.new.leaflet_points).to eq([])
    end

    it 'does not query per venue', :aggregate_failures do
      venue_with_geocoded_building(name: 'One')
      described_class.new.leaflet_points # warm one-off lookups (platform, locale) so only per venue queries differ
      baseline = query_count { described_class.new.leaflet_points }

      3.times { |i| venue_with_geocoded_building(name: "More #{i}", latitude: 48.9 + (i / 100.0)) }
      with_more = query_count { described_class.new.leaflet_points }

      expect(described_class.new.leaflet_points.size).to eq(4)
      expect(with_more).to eq(baseline)
    end
  end

  describe 'visible_scope' do
    it 'maps only the venues in the scope', :aggregate_failures do
      shown = venue_with_geocoded_building(name: 'Shown Hall')
      venue_with_geocoded_building(name: 'Hidden Hall', privacy: 'private')

      map = described_class.new
      map.visible_scope = Venue.where(id: shown.id).order(:name)

      expect(map.records.map(&:id)).to eq([shown.id])
      expect(map.leaflet_points.size).to eq(1)
    end
  end

  describe 'VenuesHelper#venues_map' do
    it 'is scoped to what the viewer may see' do
      visible = Venue.where(privacy: 'public')
      helper = Class.new do
        include VenuesHelper

        define_method(:policy_scope) { |_model| visible }
      end.new

      expect(helper.venues_map.instance_variable_get(:@visible_scope)).to eq(visible)
    end
  end
end

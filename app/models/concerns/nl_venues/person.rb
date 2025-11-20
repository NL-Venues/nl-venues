# frozen_string_literal: true

module NlVenues
  # ActiveSupport Concern for Person model
  module Person
    extend ActiveSupport::Concern

    included do
      def venue_communities
        member_communities.where(type: 'VenueCommunity')
      end

      def venues
        venue_communities.includes(:venue).map(&:venue)
      end

      def valid_event_host_ids
        [id] + venues.pluck(:id)
      end
    end
  end
end

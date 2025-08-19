# frozen_string_literal: true

module NlVenues
  module EventPolicy
    extend ActiveSupport::Concern

    included do
      def create?
        super || venue_access?
      end
    end

    def venue_access?
      record.host_venues.any? ||
        agent.venues.any?
    end
  end
end

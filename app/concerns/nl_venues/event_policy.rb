# frozen_string_literal: true

module NlVenues
  # ActiveSupport Concern for EventPolicy
  module EventPolicy
    extend ActiveSupport::Concern

    included do
      def create?
        super || venue_access?
      end
    end

    def venue_access?
      return false unless user.present?

      record.host_venues.any? ||
        agent.venues.any?
    end
  end
end

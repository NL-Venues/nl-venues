# frozen_string_literal: true

module NlVenues
	module Event
		extend ActiveSupport::Concern

		included do
			has_many :host_venues, through: :event_hosts, source: :host, source_type: 'Venue'
			validate :venue_event_creation

			def venue_event_creation
				return unless (creator_id.present? && host_venues.any?)

				venues_overlap = (creator.venues & host_venues).any?

				unless venues_overlap
					errors.add(:host_venues, 'You do not have permission to create an event for this host.')
				end
			end
		end
	end
end
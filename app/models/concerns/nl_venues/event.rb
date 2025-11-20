# frozen_string_literal: true

module NlVenues
  # ActiveSupport Concern for Event model
  module Event
    extend ActiveSupport::Concern

    included do
      has_many :host_venues, through: :event_hosts, source: :host, source_type: 'Venue'
      validate :host_event_creation

      # TODO: validation currently not working as expected
      def host_event_creation
        return unless creator_id.present? && event_hosts.any?

        return if event_host_member?(creator)

        errors.add(:event_hosts, I18n.t('pundit.errors.create', resource: 'Event'))
      end

      def event_host_member?(person)
        can_represent_host = event_hosts.any? && person.valid_event_host_ids.any?

        has_common_hosts = event_hosts.to_a.map(&:host_id).intersect?(person.valid_event_host_ids)
        can_represent_host && has_common_hosts
      end
    end
  end
end

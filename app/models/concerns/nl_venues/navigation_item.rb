# frozen_string_literal: true

module NlVenues
  module NavigationItem # rubocop:todo Style/Documentation
    extend ::ActiveSupport::Concern

    included do
      self.route_names = route_names.merge({
                                             artists: 'artists_url',
                                             deal_types: 'deal_types_url',
                                             ticket_sale_options: 'ticket_sale_options_url',
                                             tours: 'tours_url',
                                             venues: 'venues_url'
                                           })
    end
  end
end

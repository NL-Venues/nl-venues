# frozen_string_literal: true

ActiveSupport::Reloader.to_prepare do
  require_dependency 'better_together/navigation_item'
  require_dependency 'better_together/infrastructure/building'
  require_dependency 'better_together/geography/map'
  require 'better_together/event'
  require 'better_together/person'

  BetterTogether::NavigationItem.include(NlVenues::NavigationItem)
  BetterTogether::Geography::Map.include(NlVenues::Map)
  BetterTogether::Infrastructure::Building.include(NlVenues::Building)
  BetterTogether::Event.include(NlVenues::Event)
  BetterTogether::Person.include(NlVenues::Person)
end

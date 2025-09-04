# frozen_string_literal: true

ActiveSupport::Reloader.to_prepare do
  require 'better_together/event_policy'

  BetterTogether::EventPolicy.include(NlVenues::EventPolicy)
end

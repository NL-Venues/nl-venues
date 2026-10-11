# frozen_string_literal: true

# Buildings created for a public venue inherit its public privacy
# (VenueBuilding#set_new_building_details), but the building's own placeholder
# community is private, so CE's privacy ceiling would reject every new building.
# Visibility is governed by policy, matching the Venue exemption.
module BuildingPrivacyCeilingExemption
  def privacy_ceiling_exempt?
    true
  end
end

Rails.application.config.to_prepare do
  BetterTogether::Infrastructure::Building.prepend(BuildingPrivacyCeilingExemption)
end

# frozen_string_literal: true

# Join record between a deal type and a venue offer
class VenueCommunity < BetterTogether::Community
  has_one :venue, foreign_key: :community_id

  alias members person_members
  alias memberships person_community_memberships

  accepts_nested_attributes_for :person_community_memberships, reject_if: :all_blank, allow_destroy: true

  # Polymorphic links (notifications, mailers) look up venue_community_path, which no route defines.
  # Keep the model's own i18n and param keys but route like the base community.
  def self.model_name
    @model_name ||= super.tap do |name|
      base = BetterTogether::Community.model_name
      name.instance_variable_set(:@route_key, base.route_key)
      name.instance_variable_set(:@singular_route_key, base.singular_route_key)
    end
  end

  def card_image
    return super unless venue

    venue.primary_image&.media
  end

  def optimized_card_image
    return super unless venue

    venue.primary_image&.media
  end

  def to_partial_path
    becomes(self.class.base_class).to_partial_path
  end
end

# frozen_string_literal: true

# Manages Venues
class VenuesController < BetterTogether::FriendlyResourceController
  SHOW_PRELOADS = [
    :map,
    { venue_buildings: { building: %i[address space] } },
    { venue_images: { image: { media_attachment: :blob } } },
    { venue_offers: %i[deal_types ticket_sale_options] },
    { stages: [{ tech_specs_attachment: :blob }, { stage_plot_attachment: :blob }, { seating_chart_attachment: :blob }] },
    { contacts: %i[phone_numbers email_addresses addresses social_media_accounts website_links] },
    { hosted_events: [:location, :categories, { event_hosts: :host }] }
  ].freeze

  before_action if: -> { Rails.env.development? } do
    # Make sure that all BLock subclasses are loaded in dev to generate new block buttons
    BetterTogether::Content::Block.load_all_subclasses
  end

  def edit
    @buildings = policy_scope(BetterTogether::Infrastructure::Building)
    super
  end

  protected

  def resource_class
    Venue
  end

  def resource_collection
    super.includes(venue_images: { image: { media_attachment: :blob } })
  end

  def set_resource_instance
    super
    return unless @resource&.persisted?

    @resource = policy_scope(resource_class).preload(SHOW_PRELOADS).find(@resource.id)
    instance_variable_set("@#{resource_name}", @resource)
  end
end

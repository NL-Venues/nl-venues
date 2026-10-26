# frozen_string_literal: true

# Manages Venues
class VenuesController < BetterTogether::FriendlyResourceController
  INDEX_PRELOADS = [
    :string_translations, :stages, :venue_offers,
    { venue_images: { image: { media_attachment: :blob } } },
    { venue_buildings: { building: :address } }
  ].freeze

  # Everything the show page reads. The events block renders CE's event cards and policies,
  # which read the hosts, categories, location, recurrence, series link and cover image of each event.
  SHOW_PRELOADS = [
    :string_translations, :rich_text_translations,
    :map,
    { venue_buildings: { building: %i[address space] } },
    { venue_images: { image: { media_attachment: :blob } } }, { images: { media_attachment: :blob } },
    { venue_offers: %i[deal_types ticket_sale_options] },
    { stages: [:string_translations, :rich_text_translations,
               { tech_specs: { file_attachment: :blob } }, { stage_plot: { file_attachment: :blob } },
               { seating_chart: { file_attachment: :blob } }] },
    { contacts: %i[phone_numbers email_addresses addresses social_media_accounts website_links] },
    { hosted_events: [:string_translations, :rich_text_translations, :location, :recurrence, :parent_series,
                      { categories: [:string_translations, { cover_image_attachment: :blob }] }, { event_hosts: :host },
                      { cover_image_attachment: :blob }] }
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

  # The index card reads the primary image, building address and primary stage and offer of every venue.
  # CE finds the venue without the collection's preloads, so load it again with them.
  def set_resource_instance
    super
    return unless @resource&.persisted?

    @resource = resource_collection.find(@resource.id)
    instance_variable_set("@#{resource_name}", @resource)
  end

  def resource_collection
    @resources ||= policy_scope(resource_class).preload(action_name == 'show' ? SHOW_PRELOADS : INDEX_PRELOADS)

    instance_variable_set("@#{resource_name(plural: true)}", @resources)
  end
end

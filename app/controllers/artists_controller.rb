# frozen_string_literal: true

# CRUD for artists
class ArtistsController < BetterTogether::FriendlyResourceController
  # The card reads the name, description and cover image of every artist.
  CARD_PRELOADS = [:string_translations, :rich_text_translations, { cover_image_attachment: :blob }].freeze

  protected

  def resource_class
    Artist
  end

  def resource_collection
    @resources ||= policy_scope(resource_class).preload(CARD_PRELOADS)

    instance_variable_set("@#{resource_name(plural: true)}", @resources)
  end
end

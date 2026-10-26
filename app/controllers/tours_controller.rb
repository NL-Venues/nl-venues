# frozen_string_literal: true

# CRUD for Tours
class ToursController < BetterTogether::FriendlyResourceController
  # The card reads the name, description and cover image of every tour.
  CARD_PRELOADS = [:string_translations, :rich_text_translations, { cover_image_attachment: :blob }].freeze

  def index
    @draft_tours = @tours.draft
    @upcoming_tours = @tours.upcoming
    @past_tours = @tours.past
  end

  protected

  def resource_class
    Tour
  end

  def resource_collection
    @resources ||= policy_scope(resource_class).preload(CARD_PRELOADS)

    instance_variable_set("@#{resource_name(plural: true)}", @resources)
  end
end

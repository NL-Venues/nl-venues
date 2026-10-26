# frozen_string_literal: true

require_dependency 'better_together/content/block'

# Join model between Venue and BetterTogether::Content::Image
class VenueImage < ApplicationRecord
  include BetterTogether::Positioned
  include BetterTogether::PrimaryFlag

  primary_flag_scope(:venue_id)
  belongs_to :venue
  belongs_to :image, class_name: 'BetterTogether::Content::Image', inverse_of: :venue_image

  after_save :sync_image_privacy

  accepts_nested_attributes_for :image, reject_if: :all_blank

  def self.permitted_attributes(id: false, destroy: false)
    [
      :venue_id,
      {
        # The image always takes its venue's privacy, so it is never set from the form.
        image_attributes: ::BetterTogether::Content::Image.permitted_attributes(id: true) - [:privacy]
      }
    ] + super
  end

  def image
    super || build_image
  end

  private

  # update_columns on purpose: the image's visibility is the venue's, which was already governed (and
  # agreement-checked) when the venue was published; validating again would block adding an image.
  def sync_image_privacy
    return if image.blank? || !image.persisted? || image.privacy == venue.privacy

    image.update_columns(privacy: venue.privacy, updated_at: Time.current)
  end
end

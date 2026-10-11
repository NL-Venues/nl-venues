# frozen_string_literal: true

# CE's media gate (ActiveStorageSecurity) authorizes an image block by the block's own privacy and
# page placement. Venue images are blocks attached through VenueImage, not placed on a page, so they
# must be authorized as their venue: the same people who can see the venue can see its images.
# VenueImage keeps the block privacy equal to the venue's as a fallback; this makes the venue the
# source of truth. Temporary: remove when CE ships a blob authorization owner hook.
module VenueImageAuthorizationOwner
  extend ActiveSupport::Concern

  included do
    has_one :venue_image, foreign_key: :image_id, inverse_of: :image, dependent: nil
  end

  def blob_authorization_owner
    venue_image&.venue
  end
end

# Makes CE's media gate authorize venue images as their venue and cache them privately when non-public.
module VenueImageBlobAuthorization
  private

  def resolve_authorizable_record(record)
    owner = record.try(:blob_authorization_owner)
    owner.presence || super
  end

  # The shared-cache decision keys on scan status only, so a non-public venue image would still be
  # cacheable. Force private caching for any media owned by a non-public venue.
  def apply_media_cache_headers
    super
    owner = resolve_authorizable_record(attachment_record_for(@blob)) if @blob.present?
    return unless owner.is_a?(Venue) && !owner.privacy_public?

    response.set_header('X-BTS-Cache-Scope', BetterTogether::MediaCachePolicy::PRIVATE_SCOPE)
    response.headers['Cache-Control'] = BetterTogether::MediaCachePolicy::PRIVATE_CACHE_CONTROL
  end
end

Rails.application.config.to_prepare do
  image_class = BetterTogether::Content::Image
  image_class.include(VenueImageAuthorizationOwner) unless image_class.include?(VenueImageAuthorizationOwner)

  security = BetterTogether::ActiveStorageSecurity
  security.prepend(VenueImageBlobAuthorization) unless security.include?(VenueImageBlobAuthorization)
end

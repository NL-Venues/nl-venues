# frozen_string_literal: true

# Venue images are Content::Image blocks attached through venue_images, not placed on a page, so CE's
# page-based privacy backfill skipped them and they kept the 'private' column default. CE 0.11's media
# gate then answers 401 to anonymous visitors for images of public venues.
#
# A venue image shows to the same people as its venue, so the block takes the venue's privacy. If one
# image is shared by several venues the most restrictive privacy wins. Raw SQL: the venue's visibility
# was already governed when it was published, so the publishing-agreement validation is not invoked.
# Idempotent (only rows that differ). `down` is a no-op: restoring 'private' would re-break the images.
class AlignVenueImagePrivacyWithVenue < ActiveRecord::Migration[8.1]
  ALIGN_SQL = <<~SQL.squish
    UPDATE better_together_content_blocks b
    SET    privacy = t.privacy, updated_at = NOW()
    FROM (
      SELECT vi.image_id,
             CASE WHEN bool_and(v.privacy = 'public') THEN 'public'
                  WHEN bool_and(v.privacy IN ('public', 'community')) THEN 'community'
                  ELSE 'private' END AS privacy
      FROM   venue_images vi
      JOIN   venues v ON v.id = vi.venue_id
      GROUP  BY vi.image_id
    ) t
    WHERE  b.id = t.image_id AND b.privacy <> t.privacy
  SQL

  def up
    return unless schema_ready?

    say "aligned #{execute(ALIGN_SQL).cmd_tuples} venue image block(s) with their venue privacy"
  end

  def down
    # Intentionally empty, see the header comment.
  end

  private

  def schema_ready?
    %i[venue_images venues better_together_content_blocks].all? { |table| table_exists?(table) } &&
      column_exists?(:better_together_content_blocks, :privacy) && column_exists?(:venues, :privacy)
  end
end

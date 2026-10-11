# frozen_string_literal: true

namespace :venues do
  desc 'Report venue image blocks whose privacy differs from their venue (FIX=1 aligns them)'
  task audit_image_privacy: :environment do
    drifted = VenueImage.joins(:venue, :image).where('venues.privacy <> better_together_content_blocks.privacy')
    puts "#{drifted.count} venue image block(s) differ from their venue privacy"
    drifted.includes(:venue, :image).find_each do |venue_image|
      puts "  venue #{venue_image.venue.slug}: venue=#{venue_image.venue.privacy} image=#{venue_image.image.privacy}"
      venue_image.send(:sync_image_privacy) if ENV['FIX'] == '1'
    end
    puts 'aligned' if ENV['FIX'] == '1'
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('db/migrate/20261009180000_align_venue_image_privacy_with_venue')

RSpec.describe AlignVenueImagePrivacyWithVenue do
  def block_for(venue, block = create(:better_together_content_image, privacy: 'private'))
    VenueImage.create!(venue:, image: block)
    block
  end

  def run_migration
    migration = described_class.new
    migration.verbose = false
    migration.up
  end

  it 'makes images of a public venue public and leaves private venues private', :aggregate_failures do
    blocks = [create(:venue, :public), create(:venue)].map { |venue| block_for(venue) }
    blocks.each { |block| block.update_columns(privacy: 'private') }

    run_migration

    expect(blocks.map { |block| block.reload.privacy }).to eq(%w[public private])
  end

  it 'gives a shared image the most restrictive venue privacy' do
    shared = block_for(create(:venue, :public))
    VenueImage.create!(venue: create(:venue), image: shared)
    shared.update_columns(privacy: 'public')

    run_migration

    expect(shared.reload.privacy).to eq('private')
  end

  it 'ignores images that no venue uses and is idempotent', :aggregate_failures do
    orphan = create(:better_together_content_image, privacy: 'private')
    block = block_for(create(:venue, :public)).tap { |image| image.update_columns(privacy: 'private') }

    2.times { run_migration }

    expect([orphan, block].map { |image| image.reload.privacy }).to eq(%w[private public])
  end
end

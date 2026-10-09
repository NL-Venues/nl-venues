# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VenueImage, type: :model do
  let(:image) { create(:better_together_content_image, privacy: 'private') }

  def attach(venue, block = create(:better_together_content_image, privacy: 'private'))
    described_class.create!(venue:, image: block)
    block.reload
  end

  it 'gives the image the privacy of a public venue' do
    expect(attach(create(:venue, :public)).privacy).to eq('public')
  end

  it 'keeps the image private for a private venue' do
    expect(attach(create(:venue)).privacy).to eq('private')
  end

  it 'applies a venue privacy change to all its images', :aggregate_failures do
    venue = create(:venue)
    blocks = Array.new(2) { attach(venue) }

    %w[public private].each do |privacy|
      venue.update!(privacy:)
      expect(blocks.map { |block| block.reload.privacy }).to all(eq(privacy))
    end
  end

  it 'does not touch the images of other venues' do
    other = attach(create(:venue, :public))
    attach(create(:venue)).tap { |block| block.venue_image.venue.update!(privacy: 'public') }

    expect(other.reload.privacy).to eq('public')
  end

  it 'never takes the image privacy from the form' do
    permitted = described_class.permitted_attributes.find { |attr| attr.is_a?(Hash) }[:image_attributes]
    expect(permitted).not_to include(:privacy)
  end

  it 'authorizes the image as its venue' do
    venue = create(:venue)
    expect(attach(venue, image).blob_authorization_owner).to eq(venue)
  end
end

# frozen_string_literal: true

require 'rails_helper'

# Venue images show to the same people as their venue (see ce_venue_image_authorization_patch).
RSpec.describe 'Venue image media access', type: :request do
  let(:host_platform) do
    BetterTogether::Platform.find_by(host: true) || create(:better_together_platform, :host, privacy: 'public')
  end
  let(:public_venue) { create(:venue, :public) }
  let(:private_venue) { create(:venue) }
  let(:public_image) { attach_image(public_venue) }
  let(:private_image) { attach_image(private_venue) }

  def attach_image(venue)
    block = create(:better_together_content_image, privacy: 'private')
    VenueImage.create!(venue:, image: block)
    block
  end

  def media_path(block)
    rails_storage_proxy_path(block.media, only_path: true)
  end

  before do
    host_platform.community&.update_columns(privacy: 'public')
    host_platform.update_columns(privacy: 'public')
    BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup').mark_completed
  end

  after { Warden.test_reset! }

  context 'when anonymous' do
    it 'serves an image of a public venue' do
      get media_path(public_image)
      expect(response).to have_http_status(:ok)
    end

    it 'refuses an image of a private venue' do
      get media_path(private_image)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in without platform management' do
    before { login_as(create(:nl_venues_user, :confirmed), scope: :user) }

    it 'serves an image of a public venue' do
      get media_path(public_image)
      expect(response).to have_http_status(:ok)
    end

    it 'refuses an image of a private venue' do
      get media_path(private_image)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when a platform manager' do
    before { login_as(create(:nl_venues_user, :confirmed, :platform_manager), scope: :user) }

    it 'serves an image of a private venue' do
      get media_path(private_image)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids shared caching of a private venue image' do
      get media_path(private_image)
      expect(response.headers['Cache-Control']).to include('no-store')
    end

    it 'does not force private caching on a public venue image' do
      get media_path(public_image)
      expect(response.headers['Cache-Control'].to_s).not_to include('no-store')
    end
  end
end

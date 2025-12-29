# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Venues', type: :request do
  let(:locale) { I18n.default_locale }
  let!(:venue) { create(:venue, :public) }

  before do
    # Configure host platform without including DeviseSessionHelpers to avoid route conflicts
    create(:better_together_platform, :host, privacy: 'public')
    wizard = BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup')
    wizard.mark_completed
  end

  describe 'URL helpers' do
    it 'generates correct venues index path' do
      expect(venues_path(locale:)).to eq("/#{locale}/venues")
    end

    it 'generates correct venue show path' do
      expect(venue_path(venue, locale:)).to eq("/#{locale}/venues/#{venue.slug}")
    end
  end

  describe 'GET /venues' do
    it 'renders the index page' do
      get venues_path(locale:)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /venues/:id' do
    it 'renders the show page' do
      get venue_path(venue, locale:)
      expect(response).to have_http_status(:ok)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

# Notifications and mailers build links with polymorphic_path, which looks up
# venue_community_path for a VenueCommunity. CE only defines community_path.
RSpec.describe 'VenueCommunity polymorphic paths', type: :routing do
  let(:locale) { I18n.default_locale }
  let(:community) { create(:venue).community }
  let(:helpers) { BetterTogether::Engine.routes.url_helpers }

  it 'is a VenueCommunity' do
    expect(community).to be_a(VenueCommunity)
  end

  it 'routes the same as the base community' do
    expected = helpers.polymorphic_path(community.becomes(BetterTogether::Community), locale:)

    expect(helpers.polymorphic_path(community, locale:)).to eq(expected)
  end

  it 'keeps its own param key' do
    expect(VenueCommunity.model_name.param_key).to eq('venue_community')
  end

  it 'keeps its own i18n key' do
    expect(VenueCommunity.model_name.i18n_key).to eq(:venue_community)
  end

  it 'also builds a url' do
    expect(helpers.polymorphic_url(community, locale:, host: 'example.test')).to start_with('http://example.test/')
  end
end

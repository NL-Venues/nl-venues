# frozen_string_literal: true

require 'rails_helper'

# CE enforces the Content-Security-Policy, so every inline script must carry the request nonce.
RSpec.describe 'Inline scripts and CSP', type: :request do
  before do
    host = BetterTogether::Platform.find_by(host: true) || create(:better_together_platform, :host, privacy: 'public')
    host.community&.update_columns(privacy: 'public')
    host.update_columns(privacy: 'public')
    BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup').mark_completed
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GTAG_ID').and_return('G-TEST123')
  end

  let(:page_scripts) do
    get "/#{I18n.default_locale}"
    Nokogiri::HTML(response.body).css('script')
  end

  it 'gives every inline script a nonce', :aggregate_failures do
    inline = page_scripts.reject { |script| script['src'] }
    nonces = inline.filter_map { |script| script['nonce'] }

    expect(inline).not_to be_empty
    expect(nonces.size).to eq(inline.size)
    expect(response.headers['Content-Security-Policy']).to include("'nonce-#{nonces.first}'")
  end

  it 'no longer ships the scroll progress bar as inline script' do
    expect(page_scripts.map(&:text).join).not_to include('scroll-progress-bar')
  end

  it 'loads the Google tag when GTAG_ID is set' do
    expect(page_scripts.map { |script| script['src'] }.compact).to include('https://www.googletagmanager.com/gtag/js?id=G-TEST123')
  end
end

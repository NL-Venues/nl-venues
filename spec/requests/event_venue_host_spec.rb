# frozen_string_literal: true

require 'rails_helper'

# CE's event page renders its hosts with `render hosts`, so a Venue host is looked up by its
# to_partial_path ('venues/venue'). This guards that lookup, whether or not Rails prefixes the
# engine controller's namespace onto it.
RSpec.describe 'Event pages with a venue host', type: :request do
  let(:locale) { I18n.default_locale }
  let(:venue) { create(:venue, :public, name: 'The Majestic') }
  let(:event) { create(:better_together_event, :with_simple_location, privacy: 'public') }

  before do
    host = BetterTogether::Platform.find_by(host: true) || create(:better_together_platform, :host, privacy: 'public')
    host.community&.update_columns(privacy: 'public')
    host.update_columns(privacy: 'public')
    BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup').mark_completed
    create(:better_together_event_host, event:, host: venue)
  end

  it 'renders the venue card in the event hosts section', :aggregate_failures do
    get better_together.event_path(event, locale:)

    expect(response).to have_http_status(:ok)
    hosts = Nokogiri::HTML(response.body).at_css("##{ActionView::RecordIdentifier.dom_id(event, :event_hosts)}")
    expect(hosts).to be_present
    expect(hosts.at_css("##{ActionView::RecordIdentifier.dom_id(venue)}")&.text).to include('The Majestic')
  end
end

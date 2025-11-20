# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'creating a platform invitation', type: :feature do
  include DeviseSessionHelpers

  let!(:host_platform) do
    configure_host_platform
  end
  let(:invitee_email) { Faker::Internet.unique.email }

  before do
    login_as_platform_manager
  end

  # rubocop:todo RSpec/MultipleExpectations
  scenario 'with valid inputs' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    # rubocop:enable RSpec/MultipleExpectations
    visit better_together.platform_platform_invitations_path(host_platform, locale: I18n.locale)
    click_button I18n.t('better_together.platform_invitations.new_invitation')
    within '#newInvitationModal' do
      select 'Platform Invitation', from: 'platform_invitation[type]'
      select 'Community Facilitator', from: 'platform_invitation[community_role_id]'
      select 'Platform Manager', from: 'platform_invitation[platform_role_id]'
      fill_in 'platform_invitation[invitee_email]', with: invitee_email
      click_button 'Invite'
    end

    # After successful creation, we're redirected to the platform show page
    expect(page).to have_content(I18n.t('flash.generic.created', resource: I18n.t('resources.invitation')))

    # Navigate to invitations to verify the invitation was created
    visit better_together.platform_platform_invitations_path(host_platform, locale: I18n.locale)
    expect(page).to have_content(invitee_email)
  end
end

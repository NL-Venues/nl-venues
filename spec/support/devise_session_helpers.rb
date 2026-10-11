# frozen_string_literal: true

module DeviseSessionHelpers
  include FactoryBot::Syntax::Methods
  include Rails.application.routes.url_helpers
  include BetterTogether::Engine.routes.url_helpers

  def configure_host_platform
    host_platform = BetterTogether::Platform.find_by(host: true) ||
                    create(:better_together_platform, :host, privacy: 'public')
    # Auto-created host platform and community cap each other's privacy; set both directly.
    host_platform.community&.update_columns(privacy: 'public')
    host_platform.update_columns(privacy: 'public')
    host_platform.update!(host_url: spec_host_url)
    wizard = BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup')
    wizard.mark_completed
    host_platform
  end

  # Redirects are checked against the platform URL, so it must carry the Capybara server port when one is running.
  def spec_host_url
    server = Capybara.current_session.server
    server ? "http://www.example.com:#{server.port}" : 'http://www.example.com'
  end

  def login_as_platform_manager
    user = create(:nl_venues_user, :confirmed, :platform_manager)
    grant_content_publishing_agreement(user.person)
    sign_in_user(user.email, user.password)
    user
  end

  # CE requires an accepted content publishing agreement before a person can make records public.
  def grant_content_publishing_agreement(person)
    agreement = BetterTogether::Agreement.find_or_create_by!(
      identifier: BetterTogether::PublicVisibilityGate::AGREEMENT_IDENTIFIER
    )
    BetterTogether::AgreementParticipant.find_or_create_by!(agreement:, participant: person) do |participant|
      participant.accepted_at = Time.current
    end
  end

  # Plain-text entry into an ActionText (Trix) field located by its hidden input name.
  def fill_in_trix_field(locator, with:)
    plain_text = with.respond_to?(:to_plain_text) ? with.to_plain_text : with.to_s
    input_id = find("input[name='#{locator}']", visible: :all)[:id]
    find("trix-editor[input=\"#{input_id}\"]").click.set(plain_text)
  end

  # CE bot defense rejects registration submits that arrive faster than the configured minimum.
  def satisfy_bot_defense_minimum_wait(form_id)
    sleep(BetterTogether::BotDefense::Challenge::FORM_CONFIG.fetch(form_id.to_sym)[:min_submit_seconds] + 0.1)
  end

  def sign_in_user(email, password)
    Capybara.reset_session! # Ensure a new session is created
    visit new_user_session_path(locale: I18n.locale)
    fill_in_email_and_password(email, password)
    click_button 'Sign In'
  end

  def sign_up_new_user(token, email, password, person) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    visit better_together.new_user_registration_path(invitation_code: token, locale: I18n.locale)
    fill_in_registration_form(email, password, person)
    satisfy_bot_defense_minimum_wait(:registration)
    click_button 'registration-submit-btn'

    # Check if we're still on the registration page (indicating form errors)
    if current_path.include?('registration') || page.has_content?('Sign Up')
      # Capture form errors for debugging
      errors = page.all('.alert, .error, .field_with_errors').map(&:text).join('; ')
      puts "Form errors: #{errors}" if errors.present?
      puts "Current page content: #{page.body[0..500]}..." if errors.blank?
    end

    created_user = BetterTogether::User.find_by(email: email)
    raise "User creation failed for email: #{email}. Check for validation errors on the page." unless created_user

    created_user.confirm

    # If user creation failed, check for validation errors

    created_user
  end

  def fill_in_registration_form(email, password, person) # rubocop:todo Metrics/MethodLength
    fill_in_email_and_password(email, password)
    fill_in 'user[password_confirmation]', with: password
    fill_in 'user[person_attributes][name]', with: person.name
    fill_in 'user[person_attributes][identifier]', with: person.identifier
    fill_in_trix_field('user[person_attributes][description]', with: person.description)

    # Check all required agreement checkboxes
    required_agreements = %w[
      terms_of_service_agreement
      privacy_policy_agreement
      code_of_conduct_agreement
    ]
    required_agreements.each do |field_name|
      if page.has_field?(field_name)
puts "Checking required agreement: #{field_name}" # rubocop:todo Layout/IndentationWidth
check field_name
      else
puts "Warning: Required agreement field '#{field_name}' not found on page" # rubocop:todo Layout/IndentationWidth
      end
    end
  end

  def fill_in_email_and_password(email, password)
    fill_in 'user[email]', with: email
    fill_in 'user[password]', with: password
  end
end

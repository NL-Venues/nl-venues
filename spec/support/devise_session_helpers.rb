# frozen_string_literal: true

module DeviseSessionHelpers
  include FactoryBot::Syntax::Methods
  include Rails.application.routes.url_helpers
  include BetterTogether::Engine.routes.url_helpers

  def configure_host_platform
    host_platform = create(:better_together_platform, :host, privacy: 'public')
    wizard = BetterTogether::Wizard.find_or_create_by(identifier: 'host_setup')
    wizard.mark_completed
    host_platform
  end

  def login_as_platform_manager
    user = create(:nl_venues_user, :confirmed, :platform_manager)
    sign_in_user(user.email, user.password)
    user
  end

  def sign_in_user(email, password)
    Capybara.reset_session! # Ensure a new session is created
    visit new_user_session_path(locale: I18n.locale)
    fill_in_email_and_password(email, password)
    click_button 'Sign In'
  end

  def sign_up_new_user(token, email, password, person)
    visit better_together.new_user_registration_path(invitation_code: token, locale: I18n.locale)
    fill_in_registration_form(email, password, person)
    click_button 'Sign Up'

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

  def fill_in_registration_form(email, password, person)
    fill_in_email_and_password(email, password)
    fill_in 'user[password_confirmation]', with: password
    fill_in 'user[person_attributes][name]', with: person.name
    fill_in 'user[person_attributes][identifier]', with: person.identifier
    fill_in 'user[person_attributes][description]', with: person.description
    
    # Check all required agreement checkboxes
    required_agreements = [
      'terms_of_service_agreement',
      'privacy_policy_agreement',
      'code_of_conduct_agreement'
    ]
    
    required_agreements.each do |field_name|
      if page.has_field?(field_name)
        puts "Checking required agreement: #{field_name}"
        check field_name
      else
        puts "Warning: Required agreement field '#{field_name}' not found on page"
      end
    end
  end

  def fill_in_email_and_password(email, password)
    fill_in 'user[email]', with: email
    fill_in 'user[password]', with: password
  end
end

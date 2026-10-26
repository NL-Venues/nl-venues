# frozen_string_literal: true

# The sender comes from DEFAULT_FROM_EMAIL / FROM_ADDRESS (see config/application.rb)
# and the CE base mailer; the host does not override it.
class ApplicationMailer < BetterTogether::ApplicationMailer
  layout 'mailer'
end

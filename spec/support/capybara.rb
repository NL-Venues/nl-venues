# frozen_string_literal: true

require 'capybara/rspec'
require 'tmpdir'

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Options.chrome(
    args: %w[
      headless
      disable-gpu
      no-sandbox
      disable-dev-shm-usage
      window-size=1400x1400
    ]
  )
  # Generate a unique temporary directory for each session to avoid conflicts
  options.add_argument("--user-data-dir=#{Dir.mktmpdir}")

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end

Capybara.javascript_driver = :selenium_chrome_headless

# Quit every browser the run started, so none outlives the suite (a leaked Chrome per session once hung a host).
RSpec.configure do |config|
  config.after(:suite) do
    Capybara.send(:session_pool).each_value { |session| session.driver.quit if session.driver.respond_to?(:quit) }
    Capybara.reset_sessions!
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('config/initializers/content_security_policy_sources')

RSpec.describe NlVenuesContentSecurityPolicy do
  describe '.storage_origin' do
    it 'uses the S3-compatible endpoint when one is configured' do
      expect(described_class.storage_origin('S3_ENDPOINT' => 'https://s3.btsdev.ca')).to eq('https://s3.btsdev.ca')
    end

    it 'falls back to the AWS bucket host' do
      env = { 'S3_BUCKET_NAME' => 'nlvenues-uploads', 'S3_REGION' => 'ca-central-1' }

      expect(described_class.storage_origin(env)).to eq('https://nlvenues-uploads.s3.ca-central-1.amazonaws.com')
    end

    it 'returns nothing without storage configuration' do
      expect(described_class.storage_origin({})).to be_nil
    end
  end

  describe '.register' do
    around do |example|
      registry = BetterTogether.registered_content_security_policy_sources
      original = registry.transform_values(&:dup)
      example.run
    ensure
      # Keep the registry's default proc: Hash#replace would drop it.
      registry.clear
      original.each { |directive, sources| registry[directive].concat(sources) }
    end

    it 'registers the Google tag origins only when GTAG_ID is set', :aggregate_failures do
      described_class.register('GTAG_ID' => 'G-TEST', 'S3_ENDPOINT' => 'https://s3.btsdev.ca')

      registered = BetterTogether.registered_content_security_policy_sources
      expect(registered[:script_src]).to include('https://www.googletagmanager.com')
      expect(registered[:connect_src]).to include('https://www.google-analytics.com', 'https://s3.btsdev.ca')
      expect(registered[:img_src]).to include('https://s3.btsdev.ca', 'https://www.google-analytics.com')
    end

    it 'registers no analytics origins without GTAG_ID', :aggregate_failures do
      BetterTogether.registered_content_security_policy_sources.clear

      described_class.register({})

      expect(BetterTogether.registered_content_security_policy_sources[:script_src]).to be_empty
      expect(BetterTogether.registered_content_security_policy_sources[:connect_src]).to be_empty
    end
  end
end

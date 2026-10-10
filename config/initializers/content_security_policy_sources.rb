# frozen_string_literal: true

# CE builds the Content-Security-Policy from importmap pins, the environment and these registered
# sources (read per request). Everything this host app loads from another origin is registered here so
# a deployment needs no CSP_* environment variables: the Google tag, and the origin that serves
# Active Storage files directly (presigned URLs such as the host logo, and direct uploads).
module NlVenuesContentSecurityPolicy
  GOOGLE_TAG_SCRIPT_SOURCES = %w[https://www.googletagmanager.com].freeze
  GOOGLE_TAG_CONNECT_SOURCES = %w[
    https://www.google-analytics.com
    https://region1.google-analytics.com
    https://analytics.google.com
    https://www.googletagmanager.com
  ].freeze
  GOOGLE_TAG_IMG_SOURCES = %w[https://www.google-analytics.com https://www.googletagmanager.com].freeze

  module_function

  # S3_ENDPOINT for S3-compatible storage (Garage), otherwise the AWS bucket host.
  def storage_origin(env = ENV)
    sources = BetterTogether::ContentSecurityPolicySources
    return sources.origin_for_url(env['S3_ENDPOINT']) if env['S3_ENDPOINT'].present?
    return if env['S3_BUCKET_NAME'].blank? || env['S3_REGION'].blank?

    sources.origin_for_url("https://#{env['S3_BUCKET_NAME']}.s3.#{env['S3_REGION']}.amazonaws.com")
  end

  def register(env = ENV)
    if env['GTAG_ID'].present?
      BetterTogether.register_content_security_policy_sources(:script_src, *GOOGLE_TAG_SCRIPT_SOURCES)
      BetterTogether.register_content_security_policy_sources(:connect_src, *GOOGLE_TAG_CONNECT_SOURCES)
      BetterTogether.register_content_security_policy_sources(:img_src, *GOOGLE_TAG_IMG_SOURCES)
    end

    # Direct uploads (Trix attachments) PUT the file straight to the storage origin, which is a connect-src.
    origin = storage_origin(env)
    BetterTogether.register_content_security_policy_sources(:img_src, origin)
    BetterTogether.register_content_security_policy_sources(:connect_src, origin)
  end
end

NlVenuesContentSecurityPolicy.register

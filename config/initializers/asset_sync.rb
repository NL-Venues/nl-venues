# frozen_string_literal: true

require 'uri'

if defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'

    config.aws_access_key_id = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
    config.aws_secret_access_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)

    config.aws_session_token = ENV['AWS_SESSION_TOKEN'] if ENV.key?('AWS_SESSION_TOKEN')

    # Ensure that aws_iam_roles is set to false if not explicitly required
    config.aws_iam_roles = ENV['AWS_IAM_ROLES'] == 'true'

    config.fog_directory = ENV.fetch('FOG_DIRECTORY', nil)
    config.fog_region = ENV.fetch('FOG_REGION', nil)

    # S3-compatible storage such as Garage: set ASSET_SYNC_ENDPOINT to its URL (path-style addressing).
    s3_endpoint = ENV.fetch('ASSET_SYNC_ENDPOINT', nil).presence

    # Additional configurations (commented out by default)
    # config.aws_reduced_redundancy = true
    # config.aws_signature_version = 4
    # config.aws_acl = nil
    # config.fog_host = "s3.amazonaws.com"
    # config.fog_port = "9000"
    if s3_endpoint && s3_endpoint !~ /amazonaws\.com/i
      endpoint_uri = URI.parse(s3_endpoint)
      config.fog_host = endpoint_uri.host || s3_endpoint
      config.fog_scheme = endpoint_uri.scheme || 'https'
      config.fog_port = endpoint_uri.port if endpoint_uri.port && endpoint_uri.port != endpoint_uri.default_port
      config.fog_options = { path_style: true }
    else
      config.fog_scheme = 'https'
    end
    # config.cdn_distribution_id = ENV['CDN_DISTRIBUTION_ID'] if ENV.key?('CDN_DISTRIBUTION_ID')
    # config.invalidate = ['file1.js']
    # config.existing_remote_files = "keep"
    # config.gzip_compression = true
    # config.manifest = true
    # config.include_manifest = false
    # config.remote_file_list_cache_file_path = './.asset_sync_remote_file_list_cache.json'
    # config.remote_file_list_remote_path = '/remote/asset_sync_remote_file.json'
    config.enabled = (ENV['ASSET_SYNC_ENABLED'].presence || 'true') == 'true'
    config.fail_silently = ENV['ASSET_SYNC_FAIL_SILENTLY'] == 'true'
    config.log_silently = true
    config.concurrent_uploads = true
  end
end

# frozen_string_literal: true

# This migration comes from better_together (originally 20260313003000)
class AddOauthCredentialsToBetterTogetherPlatformConnections < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:better_together_platform_connections,
                          :oauth_client_id)
      add_column :better_together_platform_connections, :oauth_client_id,
                 :string
    end
    unless column_exists?(:better_together_platform_connections,
                          :oauth_client_secret)
      add_column :better_together_platform_connections, :oauth_client_secret,
                 :text
    end

    return if index_name_exists?(:better_together_platform_connections,
                                 'index_bt_platform_connections_on_oauth_client_id')

    add_index :better_together_platform_connections,
              :oauth_client_id,
              unique: true,
              name: 'index_bt_platform_connections_on_oauth_client_id'
  end
end

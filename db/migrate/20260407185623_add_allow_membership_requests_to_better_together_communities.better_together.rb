# frozen_string_literal: true

# This migration comes from better_together (originally 20260405191500)
class AddAllowMembershipRequestsToBetterTogetherCommunities < ActiveRecord::Migration[7.1]
  def change
    add_column :better_together_communities, :allow_membership_requests, :boolean, default: false, null: false
  end
end

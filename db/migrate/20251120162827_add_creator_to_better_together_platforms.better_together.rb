# frozen_string_literal: true

# This migration comes from better_together (originally 20251107222131)
# Adds creator association to platforms
class AddCreatorToBetterTogetherPlatforms < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:better_together_platforms, :creator_id)

    change_table :better_together_platforms do |t|
      t.bt_creator :better_together_platforms
    end
  end
end

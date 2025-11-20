# frozen_string_literal: true

# This migration comes from better_together (originally 20251107221537)
# Adds protected column to prevent deletion of platform-critical blocks
class AddProtectedToBetterTogetherContentBlocks < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:better_together_content_blocks, :protected)

    change_table :better_together_content_blocks, &:bt_protected
  end
end

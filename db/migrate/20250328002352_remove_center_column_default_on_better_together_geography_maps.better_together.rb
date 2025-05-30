# frozen_string_literal: true

# This migration comes from better_together (originally 20250328002116)
# Removes column default for geography column that's breaking rubocop. Not needed anyway (set in model)
class RemoveCenterColumnDefaultOnBetterTogetherGeographyMaps < ActiveRecord::Migration[7.1]
  def change
    change_column_default(:better_together_geography_maps, :center, nil)
  end
end

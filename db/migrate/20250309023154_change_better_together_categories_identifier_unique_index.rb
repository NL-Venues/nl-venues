# frozen_string_literal: true

class ChangeBetterTogetherCategoriesIdentifierUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :better_together_categories, :identifier, if_exists: true
    add_index :better_together_categories, %i[identifier type], unique: true
  end
end

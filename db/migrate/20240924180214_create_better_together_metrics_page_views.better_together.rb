# frozen_string_literal: true

# This migration comes from better_together (originally 20240924174704)
class CreateBetterTogetherMetricsPageViews < ActiveRecord::Migration[7.1]
  def change
    create_bt_table :page_views, prefix: :better_together_metrics do |t|
      t.bt_locale
      t.bt_references :pageable, polymorphic: true, index: true
      t.datetime :viewed_at, null: false
    end
  end
end

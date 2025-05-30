# frozen_string_literal: true

# This migration comes from better_together (originally 20250318183610)
# Create table to store calendar data
class CreateBetterTogetherCalendars < ActiveRecord::Migration[7.1]
  def change
    create_bt_table :calendars, id: :uuid do |t|
      t.bt_community
      t.bt_creator
      t.bt_identifier
      t.bt_locale
      t.bt_privacy
      t.bt_protected
    end
  end
end

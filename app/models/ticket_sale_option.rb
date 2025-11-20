# frozen_string_literal: true

# Responsible for defining ticket sale options for venues
class TicketSaleOption < ApplicationRecord
  include BetterTogether::Identifier
  include BetterTogether::Translatable

  slugged :name

  translates :name, type: :string
  translates :description, backend: :action_text
end

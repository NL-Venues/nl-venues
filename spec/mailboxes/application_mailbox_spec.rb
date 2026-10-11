# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailbox do
  it 'inherits the CE tenant-aware routing' do
    expect(described_class.superclass).to eq(BetterTogether::ApplicationMailbox)
  end
end

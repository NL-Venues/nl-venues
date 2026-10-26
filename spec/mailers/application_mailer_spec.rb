# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer do
  it 'never sends from the example.com placeholder' do
    expect(described_class.default_params[:from]).not_to include('example.com')
  end

  it 'uses the configured sender' do
    expect(described_class.default_params[:from]).to be_present
  end
end

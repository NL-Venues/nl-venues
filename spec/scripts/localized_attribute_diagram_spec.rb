# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('scripts/localized_attribute_diagram').to_s

# Fails when a translates call is added, removed or retyped without regenerating the diagram, or names no type.
RSpec.describe LocalizedAttributeDiagram do
  let(:declarations) { described_class::Scanner.scan_roots([Rails.root.to_s], base: Rails.root.to_s) }
  let(:diagram) do
    described_class.new(models: ActiveRecord::Base.descendants.select do |m|
      m.name && !m.abstract_class? && m.respond_to?(:mobility_attributes)
    end, declarations: declarations, title: 'NL Venues', generator: 'scripts/export_localized_attributes.rb')
  end

  before { Rails.application.eager_load! }

  it 'matches the committed diagram (run bin/export_localized_attributes if not)' do
    expect(diagram.current?(Rails.root.join('docs/development/localized_attributes.mmd'))).to be(true)
  end

  it 'finds no translates call without a type' do
    expect(diagram.untyped_declarations.map(&:location)).to be_empty
  end

  it 'draws this app\'s own translated attributes with their types', :aggregate_failures do
    mermaid = diagram.to_mermaid

    expect(mermaid).to include('class Venue["Venue"]', '+name : string', '+description : rich_text')
    expect(mermaid).not_to include('BetterTogether::')
  end

  it 'flags an untyped translates call' do
    decl = described_class::Scanner.scan_source("class Venue\n  translates :tagline\nend\n").first

    expect([decl.attributes, decl.explicit_type]).to eq([%w[tagline], false])
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('db/migrate/20261011000000_seed_better_together_agreements')

RSpec.describe SeedBetterTogetherAgreements do
  let(:publishing) { 'content_publishing_agreement' }

  def run_migration
    migration = described_class.new
    migration.verbose = false
    migration.up
  end

  before { BetterTogether::Agreement.where(identifier: publishing).destroy_all }

  it 'creates the agreements CE gates publishing on', :aggregate_failures do
    run_migration

    expect(BetterTogether::Agreement.find_by(identifier: publishing)).to be_present
    expect(BetterTogether::Agreement.pluck(:identifier)).to include('community_creation_agreement', 'privacy_policy')
  end

  it 'is idempotent', :aggregate_failures do
    2.times { run_migration }

    expect(BetterTogether::Agreement.where(identifier: publishing).count).to eq(1)
    expect(BetterTogether::AgreementTerm.where(identifier: 'content_publishing_agreement_summary').count).to eq(1)
  end

  context 'when CLEAR is set' do
    before { ENV['CLEAR'] = '1' }

    after { ENV.delete('CLEAR') }

    it 'never rebuilds from scratch' do
      accepted = create(:better_together_agreement_participant, agreement: create(:better_together_agreement))

      run_migration

      expect(BetterTogether::AgreementParticipant.exists?(accepted.id)).to be(true)
    end
  end
end

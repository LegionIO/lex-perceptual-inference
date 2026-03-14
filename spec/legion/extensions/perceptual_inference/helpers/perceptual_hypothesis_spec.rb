# frozen_string_literal: true

RSpec.describe Legion::Extensions::PerceptualInference::Helpers::PerceptualHypothesis do
  subject(:hypothesis) do
    described_class.new(content: 'red cube', modality: :visual, domain: :objects, prior: 0.6)
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(hypothesis.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(hypothesis.content).to eq('red cube')
    end

    it 'stores modality' do
      expect(hypothesis.modality).to eq(:visual)
    end

    it 'stores domain' do
      expect(hypothesis.domain).to eq(:objects)
    end

    it 'clamps prior to PRIOR_CEILING' do
      h = described_class.new(content: 'x', modality: :visual, prior: 1.5)
      expect(h.prior).to be_within(0.001).of(0.99)
    end

    it 'clamps prior to PRIOR_FLOOR' do
      h = described_class.new(content: 'x', modality: :visual, prior: -0.5)
      expect(h.prior).to be_within(0.001).of(0.01)
    end

    it 'initializes state as :active' do
      expect(hypothesis.state).to eq(:active)
    end

    it 'initializes likelihood at 0.5' do
      expect(hypothesis.likelihood).to be_within(0.001).of(0.5)
    end

    it 'initializes posterior equal to prior' do
      expect(hypothesis.posterior).to be_within(0.001).of(0.6)
    end

    it 'sets created_at' do
      expect(hypothesis.created_at).to be_a(Time)
    end

    it 'uses DEFAULT_PRIOR when no prior given' do
      h = described_class.new(content: 'x', modality: :visual)
      expect(h.prior).to be_within(0.001).of(0.5)
    end
  end

  describe '#compute_posterior' do
    it 'returns a float between 0 and 1' do
      result = hypothesis.compute_posterior(evidence_weight: 0.8)
      expect(result).to be_between(0.0, 1.0)
    end

    it 'updates the posterior attribute' do
      hypothesis.compute_posterior(evidence_weight: 0.8)
      expect(hypothesis.posterior).to be_between(0.0, 1.0)
    end

    it 'uses EVIDENCE_STRENGTH_FLOOR when weight is too low' do
      result = hypothesis.compute_posterior(evidence_weight: 0.001)
      expect(result).to be_between(0.0, 1.0)
    end
  end

  describe '#select!' do
    it 'transitions state to :selected' do
      hypothesis.select!
      expect(hypothesis.state).to eq(:selected)
    end
  end

  describe '#suppress!' do
    it 'transitions state to :suppressed' do
      hypothesis.suppress!
      expect(hypothesis.state).to eq(:suppressed)
    end
  end

  describe '#selected?' do
    it 'returns false when active' do
      expect(hypothesis.selected?).to be false
    end

    it 'returns true after select!' do
      hypothesis.select!
      expect(hypothesis.selected?).to be true
    end

    it 'returns false after suppress!' do
      hypothesis.suppress!
      expect(hypothesis.selected?).to be false
    end
  end

  describe '#rival_with?' do
    it 'returns true when posteriors are within RIVALRY_MARGIN' do
      other = described_class.new(content: 'blue cube', modality: :visual, prior: 0.6)
      other.instance_variable_set(:@posterior, hypothesis.posterior + 0.05)
      expect(hypothesis.rival_with?(other)).to be true
    end

    it 'returns false when posteriors differ by more than RIVALRY_MARGIN' do
      other = described_class.new(content: 'blue cube', modality: :visual, prior: 0.1)
      other.instance_variable_set(:@posterior, 0.1)
      hypothesis.instance_variable_set(:@posterior, 0.9)
      expect(hypothesis.rival_with?(other)).to be false
    end

    it 'returns false for non-hypothesis argument' do
      expect(hypothesis.rival_with?('not a hypothesis')).to be false
    end
  end

  describe '#adapt_prior' do
    it 'increases prior on :correct outcome' do
      old_prior = hypothesis.prior
      hypothesis.adapt_prior(outcome: :correct)
      expect(hypothesis.prior).to be > old_prior
    end

    it 'decreases prior on :incorrect outcome' do
      old_prior = hypothesis.prior
      hypothesis.adapt_prior(outcome: :incorrect)
      expect(hypothesis.prior).to be < old_prior
    end

    it 'stays within bounds after many correct outcomes' do
      20.times { hypothesis.adapt_prior(outcome: :correct) }
      expect(hypothesis.prior).to be <= 0.99
    end

    it 'stays within bounds after many incorrect outcomes' do
      20.times { hypothesis.adapt_prior(outcome: :incorrect) }
      expect(hypothesis.prior).to be >= 0.01
    end
  end

  describe '#decay' do
    it 'moves prior toward DEFAULT_PRIOR' do
      h = described_class.new(content: 'x', modality: :visual, prior: 0.9)
      h.decay
      expect(h.prior).to be < 0.9
    end

    it 'moves prior up from very low values' do
      h = described_class.new(content: 'x', modality: :visual, prior: 0.05)
      h.decay
      expect(h.prior).to be > 0.04
    end

    it 'marks state as :decayed when suppressed and prior hits floor' do
      h = described_class.new(content: 'x', modality: :visual, prior: 0.5)
      h.suppress!
      30.times { h.decay }
      expect(h.state).to eq(:decayed)
    end
  end

  describe '#percept_label' do
    it 'returns :vivid for posterior >= 0.8' do
      hypothesis.instance_variable_set(:@posterior, 0.85)
      expect(hypothesis.percept_label).to eq(:vivid)
    end

    it 'returns :clear for posterior in 0.6..0.8' do
      hypothesis.instance_variable_set(:@posterior, 0.7)
      expect(hypothesis.percept_label).to eq(:clear)
    end

    it 'returns :ambiguous for posterior around 0.5' do
      hypothesis.instance_variable_set(:@posterior, 0.5)
      expect(hypothesis.percept_label).to eq(:ambiguous)
    end

    it 'returns :faint for posterior in 0.2..0.4' do
      hypothesis.instance_variable_set(:@posterior, 0.3)
      expect(hypothesis.percept_label).to eq(:faint)
    end

    it 'returns :subliminal for posterior < 0.2' do
      hypothesis.instance_variable_set(:@posterior, 0.1)
      expect(hypothesis.percept_label).to eq(:subliminal)
    end
  end

  describe '#to_h' do
    it 'returns a hash with required keys' do
      h = hypothesis.to_h
      expect(h.keys).to include(:id, :content, :modality, :domain, :prior, :likelihood, :posterior, :state, :label, :created_at)
    end

    it 'rounds prior to 4 decimal places' do
      h = hypothesis.to_h
      expect(h[:prior].to_s).to match(/\A\d+\.\d{1,4}\z/)
    end
  end
end

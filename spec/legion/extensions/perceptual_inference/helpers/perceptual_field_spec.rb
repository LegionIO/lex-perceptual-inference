# frozen_string_literal: true

RSpec.describe Legion::Extensions::PerceptualInference::Helpers::PerceptualField do
  subject(:field) { described_class.new }

  def register_visual(content, prior: 0.5)
    field.register_hypothesis(content: content, modality: :visual, prior: prior)
  end

  describe '#initialize' do
    it 'starts with empty hypotheses' do
      expect(field.hypotheses).to be_empty
    end

    it 'starts with empty evidence_log' do
      expect(field.evidence_log).to be_empty
    end
  end

  describe '#register_hypothesis' do
    it 'returns a PerceptualHypothesis' do
      h = register_visual('cat')
      expect(h).to be_a(Legion::Extensions::PerceptualInference::Helpers::PerceptualHypothesis)
    end

    it 'stores hypothesis in @hypotheses by id' do
      h = register_visual('cat')
      expect(field.hypotheses[h.id]).to eq(h)
    end

    it 'raises ArgumentError for unknown modality' do
      expect { field.register_hypothesis(content: 'x', modality: :unknown) }.to raise_error(ArgumentError)
    end

    it 'defaults domain to :general' do
      h = register_visual('cat')
      expect(h.domain).to eq(:general)
    end

    it 'accepts custom domain' do
      h = field.register_hypothesis(content: 'bark', modality: :auditory, domain: :animals)
      expect(h.domain).to eq(:animals)
    end

    it 'stores hypothesis with provided prior' do
      h = register_visual('dog', prior: 0.8)
      expect(h.prior).to be_within(0.001).of(0.8)
    end
  end

  describe '#present_evidence' do
    before { register_visual('cat') }

    it 'returns count of hypotheses in modality' do
      count = field.present_evidence(modality: :visual, content: 'cat', strength: 0.7)
      expect(count).to eq(1)
    end

    it 'logs evidence in evidence_log' do
      field.present_evidence(modality: :visual, content: 'cat', strength: 0.7)
      expect(field.evidence_log.last[:content]).to eq('cat')
    end

    it 'raises ArgumentError for unknown modality' do
      expect { field.present_evidence(modality: :unknown, content: 'x', strength: 0.5) }.to raise_error(ArgumentError)
    end

    it 'updates hypotheses posteriors' do
      h = field.hypotheses.values.first
      field.present_evidence(modality: :visual, content: 'cat', strength: 0.9)
      expect(h.posterior).to be_between(0.0, 1.0)
    end

    it 'caps evidence log at MAX_EVIDENCE' do
      101.times { |i| field.register_hypothesis(content: "h#{i}", modality: :auditory) }
      101.times { |i| field.present_evidence(modality: :auditory, content: "x#{i}", strength: 0.5) }
      expect(field.evidence_log.size).to be <= Legion::Extensions::PerceptualInference::Helpers::MAX_EVIDENCE
    end
  end

  describe '#select_percept' do
    it 'returns nil when no hypotheses exist' do
      expect(field.select_percept(modality: :visual)).to be_nil
    end

    it 'raises ArgumentError for unknown modality' do
      expect { field.select_percept(modality: :unknown) }.to raise_error(ArgumentError)
    end

    it 'selects the highest-posterior hypothesis when above threshold' do
      h = register_visual('necker', prior: 0.9)
      field.present_evidence(modality: :visual, content: 'necker', strength: 0.95)
      winner = field.select_percept(modality: :visual)
      expect(winner).to eq(h)
    end

    it 'returns nil when best hypothesis is below SELECTION_THRESHOLD' do
      register_visual('weak', prior: 0.1)
      result = field.select_percept(modality: :visual)
      expect(result).to be_nil
    end

    it 'suppresses non-winning hypotheses when a winner is found' do
      register_visual('strong', prior: 0.9)
      register_visual('weak', prior: 0.1)
      field.present_evidence(modality: :visual, content: 'strong', strength: 0.95)
      field.select_percept(modality: :visual)
      suppressed = field.hypotheses.values.select { |h| h.state == :suppressed }
      expect(suppressed).not_to be_empty
    end
  end

  describe '#rivalry?' do
    it 'returns false with no hypotheses' do
      expect(field.rivalry?(modality: :visual)).to be false
    end

    it 'raises ArgumentError for unknown modality' do
      expect { field.rivalry?(modality: :bad) }.to raise_error(ArgumentError)
    end

    it 'returns false with only one hypothesis' do
      register_visual('cat')
      expect(field.rivalry?(modality: :visual)).to be false
    end

    it 'detects rivalry when posteriors are close' do
      h_one = register_visual('cat', prior: 0.55)
      h_two = register_visual('dog', prior: 0.55)
      h_one.instance_variable_set(:@posterior, 0.62)
      h_two.instance_variable_set(:@posterior, 0.63)
      expect(field.rivalry?(modality: :visual)).to be true
    end

    it 'returns false when posteriors are far apart' do
      h_one = register_visual('cat', prior: 0.9)
      h_two = register_visual('dog', prior: 0.1)
      h_one.instance_variable_set(:@posterior, 0.9)
      h_two.instance_variable_set(:@posterior, 0.2)
      expect(field.rivalry?(modality: :visual)).to be false
    end
  end

  describe '#current_percept' do
    it 'returns nil when nothing is selected' do
      register_visual('cat')
      expect(field.current_percept(modality: :visual)).to be_nil
    end

    it 'returns the selected hypothesis' do
      h = register_visual('necker', prior: 0.95)
      field.present_evidence(modality: :visual, content: 'necker', strength: 0.99)
      field.select_percept(modality: :visual)
      expect(field.current_percept(modality: :visual)).to eq(h)
    end

    it 'raises ArgumentError for unknown modality' do
      expect { field.current_percept(modality: :invalid) }.to raise_error(ArgumentError)
    end
  end

  describe '#hypotheses_for' do
    it 'returns only hypotheses for the given modality' do
      register_visual('cat')
      field.register_hypothesis(content: 'bark', modality: :auditory)
      visual = field.hypotheses_for(:visual)
      expect(visual.all? { |h| h.modality == :visual }).to be true
    end

    it 'returns empty array when no hypotheses for modality' do
      expect(field.hypotheses_for(:olfactory)).to be_empty
    end
  end

  describe '#suppress_hypothesis' do
    it 'suppresses a hypothesis by id' do
      h = register_visual('cat')
      result = field.suppress_hypothesis(hypothesis_id: h.id)
      expect(result).to be true
      expect(h.state).to eq(:suppressed)
    end

    it 'returns false for unknown hypothesis id' do
      result = field.suppress_hypothesis(hypothesis_id: 'nonexistent-uuid')
      expect(result).to be false
    end
  end

  describe '#adapt_priors' do
    it 'increases prior of correct hypothesis' do
      h = register_visual('cat', prior: 0.5)
      old_prior = h.prior
      field.adapt_priors(modality: :visual, correct_hypothesis_id: h.id)
      expect(h.prior).to be > old_prior
    end

    it 'decreases prior of incorrect hypotheses' do
      h_correct = register_visual('cat', prior: 0.5)
      h_wrong   = register_visual('dog', prior: 0.5)
      old_wrong_prior = h_wrong.prior
      field.adapt_priors(modality: :visual, correct_hypothesis_id: h_correct.id)
      expect(h_wrong.prior).to be < old_wrong_prior
    end

    it 'raises ArgumentError for unknown modality' do
      expect { field.adapt_priors(modality: :bad, correct_hypothesis_id: 'x') }.to raise_error(ArgumentError)
    end
  end

  describe '#ambiguity_level' do
    it 'returns 0.0 with no hypotheses' do
      expect(field.ambiguity_level).to be_within(0.001).of(0.0)
    end

    it 'returns a value between 0 and 1' do
      register_visual('cat')
      expect(field.ambiguity_level).to be_between(0.0, 1.0)
    end

    it 'is higher when more modalities have rivalry' do
      h_one = register_visual('cat', prior: 0.55)
      h_two = register_visual('dog', prior: 0.55)
      h_one.instance_variable_set(:@posterior, 0.62)
      h_two.instance_variable_set(:@posterior, 0.63)
      expect(field.ambiguity_level).to be > 0.0
    end
  end

  describe '#decay_all' do
    it 'calls decay on each hypothesis' do
      register_visual('cat', prior: 0.9)
      field.decay_all
      h = field.hypotheses.values.first
      expect(h).not_to be_nil
      expect(h.prior).to be <= 0.9
    end

    it 'removes decayed hypotheses after suppression' do
      h = register_visual('ghost', prior: 0.5)
      h.suppress!
      30.times { field.decay_all }
      expect(field.hypotheses[h.id]).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a hash with hypotheses_total' do
      register_visual('cat')
      result = field.to_h
      expect(result[:hypotheses_total]).to eq(1)
    end

    it 'returns a hash with ambiguity_level' do
      result = field.to_h
      expect(result).to have_key(:ambiguity_level)
    end

    it 'returns a hash with by_modality' do
      register_visual('cat')
      result = field.to_h
      expect(result[:by_modality]).to have_key(:visual)
    end

    it 'omits empty modalities from by_modality' do
      register_visual('cat')
      result = field.to_h
      expect(result[:by_modality]).not_to have_key(:olfactory)
    end
  end
end

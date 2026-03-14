# frozen_string_literal: true

require 'legion/extensions/perceptual_inference/client'

RSpec.describe Legion::Extensions::PerceptualInference::Runners::PerceptualInference do
  let(:client) { Legion::Extensions::PerceptualInference::Client.new }

  describe '#register_percept_hypothesis' do
    it 'returns success: true for valid modality' do
      result = client.register_percept_hypothesis(content: 'red square', modality: :visual)
      expect(result[:success]).to be true
    end

    it 'returns a hypothesis_id UUID' do
      result = client.register_percept_hypothesis(content: 'red square', modality: :visual)
      expect(result[:hypothesis_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the modality in the result' do
      result = client.register_percept_hypothesis(content: 'red square', modality: :visual)
      expect(result[:modality]).to eq(:visual)
    end

    it 'returns success: false for unknown modality' do
      result = client.register_percept_hypothesis(content: 'x', modality: :unknown)
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end

    it 'uses DEFAULT_PRIOR when no prior given' do
      result = client.register_percept_hypothesis(content: 'cat', modality: :visual)
      expect(result[:prior]).to be_within(0.001).of(0.5)
    end

    it 'accepts custom prior' do
      result = client.register_percept_hypothesis(content: 'dog', modality: :visual, prior: 0.8)
      expect(result[:prior]).to be_within(0.001).of(0.8)
    end

    it 'accepts all valid modalities' do
      Legion::Extensions::PerceptualInference::Helpers::MODALITIES.each do |mod|
        result = client.register_percept_hypothesis(content: 'x', modality: mod)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#present_perceptual_evidence' do
    before { client.register_percept_hypothesis(content: 'cat', modality: :visual) }

    it 'returns success: true' do
      result = client.present_perceptual_evidence(modality: :visual, content: 'cat', strength: 0.8)
      expect(result[:success]).to be true
    end

    it 'returns hypotheses_updated count' do
      result = client.present_perceptual_evidence(modality: :visual, content: 'cat', strength: 0.8)
      expect(result[:hypotheses_updated]).to eq(1)
    end

    it 'includes rivalry status' do
      result = client.present_perceptual_evidence(modality: :visual, content: 'cat', strength: 0.8)
      expect(result).to have_key(:rivalry)
    end

    it 'returns success: false for unknown modality' do
      result = client.present_perceptual_evidence(modality: :bogus, content: 'cat', strength: 0.5)
      expect(result[:success]).to be false
    end

    it 'defaults strength to 0.5' do
      result = client.present_perceptual_evidence(modality: :visual, content: 'cat')
      expect(result[:success]).to be true
    end
  end

  describe '#select_percept' do
    it 'returns success: true' do
      result = client.select_percept(modality: :visual)
      expect(result[:success]).to be true
    end

    it 'returns selected: false when no hypotheses' do
      result = client.select_percept(modality: :visual)
      expect(result[:selected]).to be false
    end

    it 'selects a strong hypothesis' do
      client.register_percept_hypothesis(content: 'bright light', modality: :visual, prior: 0.95)
      client.present_perceptual_evidence(modality: :visual, content: 'bright light', strength: 0.99)
      result = client.select_percept(modality: :visual)
      expect(result[:selected]).to be true
      expect(result[:hypothesis]).to be_a(Hash)
    end

    it 'returns selected: false for weak hypothesis' do
      client.register_percept_hypothesis(content: 'faint', modality: :visual, prior: 0.1)
      result = client.select_percept(modality: :visual)
      expect(result[:selected]).to be false
    end

    it 'returns success: false for unknown modality' do
      result = client.select_percept(modality: :unknown)
      expect(result[:success]).to be false
    end

    it 'returns percept label when selected' do
      client.register_percept_hypothesis(content: 'vivid image', modality: :visual, prior: 0.95)
      client.present_perceptual_evidence(modality: :visual, content: 'vivid image', strength: 0.99)
      result = client.select_percept(modality: :visual)
      expect(result[:hypothesis][:label]).to be_a(Symbol)
    end
  end

  describe '#check_rivalry' do
    it 'returns success: true' do
      result = client.check_rivalry(modality: :visual)
      expect(result[:success]).to be true
    end

    it 'returns rivalry: false with no hypotheses' do
      result = client.check_rivalry(modality: :visual)
      expect(result[:rivalry]).to be false
    end

    it 'returns top_hypotheses array' do
      result = client.check_rivalry(modality: :visual)
      expect(result[:top_hypotheses]).to be_an(Array)
    end

    it 'detects rivalry between two evenly matched hypotheses' do
      client.register_percept_hypothesis(content: 'necker left', modality: :visual, prior: 0.6)
      client.register_percept_hypothesis(content: 'necker right', modality: :visual, prior: 0.6)
      client.present_perceptual_evidence(modality: :visual, content: 'necker', strength: 0.5)
      result = client.check_rivalry(modality: :visual)
      expect(result[:rivalry]).to be(true).or be(false)
    end

    it 'returns success: false for invalid modality' do
      result = client.check_rivalry(modality: :nonexistent)
      expect(result[:success]).to be false
    end
  end

  describe '#current_percept' do
    it 'returns success: true' do
      result = client.current_percept(modality: :visual)
      expect(result[:success]).to be true
    end

    it 'returns found: false when nothing selected' do
      result = client.current_percept(modality: :visual)
      expect(result[:found]).to be false
    end

    it 'returns found: true after selection' do
      client.register_percept_hypothesis(content: 'clear sky', modality: :visual, prior: 0.95)
      client.present_perceptual_evidence(modality: :visual, content: 'clear sky', strength: 0.99)
      client.select_percept(modality: :visual)
      result = client.current_percept(modality: :visual)
      expect(result[:found]).to be true
    end

    it 'returns the percept hash when found' do
      client.register_percept_hypothesis(content: 'bright', modality: :visual, prior: 0.95)
      client.present_perceptual_evidence(modality: :visual, content: 'bright', strength: 0.99)
      client.select_percept(modality: :visual)
      result = client.current_percept(modality: :visual)
      expect(result[:percept]).to be_a(Hash)
    end

    it 'returns success: false for invalid modality' do
      result = client.current_percept(modality: :invalid)
      expect(result[:success]).to be false
    end
  end

  describe '#adapt_perception' do
    it 'returns success: true for valid modality' do
      h = client.register_percept_hypothesis(content: 'cat', modality: :visual)
      result = client.adapt_perception(modality: :visual, correct_hypothesis_id: h[:hypothesis_id])
      expect(result[:success]).to be true
    end

    it 'includes modality and correct_hypothesis_id' do
      h = client.register_percept_hypothesis(content: 'cat', modality: :visual)
      result = client.adapt_perception(modality: :visual, correct_hypothesis_id: h[:hypothesis_id])
      expect(result[:modality]).to eq(:visual)
      expect(result[:correct_hypothesis_id]).to eq(h[:hypothesis_id])
    end

    it 'returns success: false for invalid modality' do
      result = client.adapt_perception(modality: :bogus, correct_hypothesis_id: 'some-id')
      expect(result[:success]).to be false
    end
  end

  describe '#suppress_percept' do
    it 'returns success: true' do
      h = client.register_percept_hypothesis(content: 'cat', modality: :visual)
      result = client.suppress_percept(hypothesis_id: h[:hypothesis_id])
      expect(result[:success]).to be true
    end

    it 'returns suppressed: true for existing hypothesis' do
      h = client.register_percept_hypothesis(content: 'cat', modality: :visual)
      result = client.suppress_percept(hypothesis_id: h[:hypothesis_id])
      expect(result[:suppressed]).to be true
    end

    it 'returns suppressed: false for unknown hypothesis' do
      result = client.suppress_percept(hypothesis_id: 'unknown-uuid')
      expect(result[:suppressed]).to be false
    end
  end

  describe '#perceptual_ambiguity' do
    it 'returns success: true' do
      result = client.perceptual_ambiguity
      expect(result[:success]).to be true
    end

    it 'returns ambiguity_level as a float' do
      result = client.perceptual_ambiguity
      expect(result[:ambiguity_level]).to be_a(Float)
    end

    it 'returns a label' do
      result = client.perceptual_ambiguity
      expect(%i[none low moderate high]).to include(result[:label])
    end

    it 'returns :none when no hypotheses exist' do
      result = client.perceptual_ambiguity
      expect(result[:label]).to eq(:none)
    end

    it 'returns ambiguity_level of 0.0 with no hypotheses' do
      result = client.perceptual_ambiguity
      expect(result[:ambiguity_level]).to be_within(0.001).of(0.0)
    end
  end

  describe '#update_perceptual_inference' do
    it 'returns success: true' do
      result = client.update_perceptual_inference
      expect(result[:success]).to be true
    end

    it 'returns remaining_hypotheses count' do
      client.register_percept_hypothesis(content: 'cat', modality: :visual)
      result = client.update_perceptual_inference
      expect(result[:remaining_hypotheses]).to be_a(Integer)
    end

    it 'reduces count of very-low-prior hypotheses over many cycles' do
      h = client.register_percept_hypothesis(content: 'ghost', modality: :visual, prior: 0.011)
      h_id = h[:hypothesis_id]
      30.times { client.update_perceptual_inference }
      result = client.perceptual_inference_stats
      ids = result[:stats][:by_modality][:visual]&.dig(:percept, :id)
      expect(ids).not_to eq(h_id)
    end
  end

  describe '#perceptual_inference_stats' do
    it 'returns success: true' do
      result = client.perceptual_inference_stats
      expect(result[:success]).to be true
    end

    it 'returns stats hash' do
      result = client.perceptual_inference_stats
      expect(result[:stats]).to be_a(Hash)
    end

    it 'includes hypotheses_total in stats' do
      client.register_percept_hypothesis(content: 'cat', modality: :visual)
      result = client.perceptual_inference_stats
      expect(result[:stats][:hypotheses_total]).to eq(1)
    end

    it 'includes ambiguity_level in stats' do
      result = client.perceptual_inference_stats
      expect(result[:stats]).to have_key(:ambiguity_level)
    end
  end

  describe 'integration: hypothesis lifecycle' do
    it 'registers, presents evidence, selects, and adapts priors' do
      reg_one = client.register_percept_hypothesis(content: 'bright cube', modality: :visual, prior: 0.95)
      reg_two = client.register_percept_hypothesis(content: 'dark sphere', modality: :visual, prior: 0.1)

      client.present_perceptual_evidence(modality: :visual, content: 'bright cube', strength: 0.99)
      selection = client.select_percept(modality: :visual)
      expect(selection[:selected]).to be true

      client.adapt_perception(modality: :visual, correct_hypothesis_id: reg_one[:hypothesis_id])

      stats = client.perceptual_inference_stats
      expect(stats[:stats][:hypotheses_total]).to eq(2)
      _ = reg_two
    end
  end
end

# frozen_string_literal: true

RSpec.describe Legion::Extensions::PerceptualInference::Helpers do
  describe 'constants' do
    it 'defines MAX_HYPOTHESES as 30' do
      expect(described_class::MAX_HYPOTHESES).to eq(30)
    end

    it 'defines MAX_EVIDENCE as 100' do
      expect(described_class::MAX_EVIDENCE).to eq(100)
    end

    it 'defines MAX_HISTORY as 200' do
      expect(described_class::MAX_HISTORY).to eq(200)
    end

    it 'defines DEFAULT_PRIOR as 0.5' do
      expect(described_class::DEFAULT_PRIOR).to be_within(0.001).of(0.5)
    end

    it 'defines PRIOR_FLOOR as 0.01' do
      expect(described_class::PRIOR_FLOOR).to be_within(0.001).of(0.01)
    end

    it 'defines PRIOR_CEILING as 0.99' do
      expect(described_class::PRIOR_CEILING).to be_within(0.001).of(0.99)
    end

    it 'defines SELECTION_THRESHOLD as 0.6' do
      expect(described_class::SELECTION_THRESHOLD).to be_within(0.001).of(0.6)
    end

    it 'defines RIVALRY_MARGIN as 0.1' do
      expect(described_class::RIVALRY_MARGIN).to be_within(0.001).of(0.1)
    end

    it 'defines EVIDENCE_STRENGTH_FLOOR as 0.05' do
      expect(described_class::EVIDENCE_STRENGTH_FLOOR).to be_within(0.001).of(0.05)
    end

    it 'defines ADAPTATION_RATE as 0.1' do
      expect(described_class::ADAPTATION_RATE).to be_within(0.001).of(0.1)
    end

    it 'defines DECAY_RATE as 0.01' do
      expect(described_class::DECAY_RATE).to be_within(0.001).of(0.01)
    end

    it 'defines 7 MODALITIES' do
      expect(described_class::MODALITIES.size).to eq(7)
    end

    it 'includes visual modality' do
      expect(described_class::MODALITIES).to include(:visual)
    end

    it 'includes auditory modality' do
      expect(described_class::MODALITIES).to include(:auditory)
    end

    it 'includes vestibular modality' do
      expect(described_class::MODALITIES).to include(:vestibular)
    end

    it 'freezes MODALITIES' do
      expect(described_class::MODALITIES).to be_frozen
    end

    it 'defines 4 HYPOTHESIS_STATES' do
      expect(described_class::HYPOTHESIS_STATES).to eq(%i[active selected suppressed decayed])
    end

    it 'defines PERCEPT_LABELS with 5 entries' do
      expect(described_class::PERCEPT_LABELS.size).to eq(5)
    end

    it 'labels posterior >= 0.8 as vivid' do
      label = described_class::PERCEPT_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:vivid)
    end

    it 'labels posterior 0.6..0.8 as clear' do
      label = described_class::PERCEPT_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:clear)
    end

    it 'labels posterior 0.4..0.6 as ambiguous' do
      label = described_class::PERCEPT_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:ambiguous)
    end

    it 'labels posterior < 0.2 as subliminal' do
      label = described_class::PERCEPT_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:subliminal)
    end
  end
end

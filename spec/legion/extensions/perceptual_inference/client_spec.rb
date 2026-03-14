# frozen_string_literal: true

require 'legion/extensions/perceptual_inference/client'

RSpec.describe Legion::Extensions::PerceptualInference::Client do
  subject(:client) { described_class.new }

  it 'can be instantiated without arguments' do
    expect(client).to be_a(described_class)
  end

  it 'includes the runner module' do
    expect(client).to respond_to(:register_percept_hypothesis)
    expect(client).to respond_to(:present_perceptual_evidence)
    expect(client).to respond_to(:select_percept)
    expect(client).to respond_to(:check_rivalry)
    expect(client).to respond_to(:current_percept)
    expect(client).to respond_to(:adapt_perception)
    expect(client).to respond_to(:suppress_percept)
    expect(client).to respond_to(:perceptual_ambiguity)
    expect(client).to respond_to(:update_perceptual_inference)
    expect(client).to respond_to(:perceptual_inference_stats)
  end

  it 'accepts an injected PerceptualField' do
    custom_field = Legion::Extensions::PerceptualInference::Helpers::PerceptualField.new
    custom_field.register_hypothesis(content: 'injected', modality: :visual)
    client_with_field = described_class.new(field: custom_field)
    stats = client_with_field.perceptual_inference_stats
    expect(stats[:stats][:hypotheses_total]).to eq(1)
  end

  it 'maintains isolated state across instances' do
    c_one = described_class.new
    c_two = described_class.new
    c_one.register_percept_hypothesis(content: 'cat', modality: :visual)
    expect(c_two.perceptual_inference_stats[:stats][:hypotheses_total]).to eq(0)
  end
end

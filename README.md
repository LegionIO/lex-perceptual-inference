# lex-perceptual-inference

Bayesian perceptual inference for the LegionIO cognitive architecture. Maintains competing hypotheses per sensory modality and resolves them using evidence-weighted posteriors.

## What It Does

For each sensory modality, maintains a field of competing perceptual hypotheses with Bayesian priors, likelihoods, and posteriors. As evidence arrives, posteriors are updated. When one hypothesis exceeds the selection threshold, it becomes the dominant percept. When two hypotheses have nearly equal posteriors, rivalry is detected. Priors adapt based on whether predictions were correct.

## Usage

```ruby
client = Legion::Extensions::PerceptualInference::Client.new

# Register a hypothesis for a visual modality
result = client.register_percept_hypothesis(
  content:  'moving object in upper-left quadrant',
  modality: :visual,
  domain:   :environment,
  prior:    0.6
)
hyp_id = result[:hypothesis_id]

# Present evidence
client.present_perceptual_evidence(
  modality: :visual,
  content:  'upper-left',
  strength: 0.8
)

# Select the winning percept
client.select_percept(modality: :visual)
# => { selected: true, hypothesis: { content: '...', posterior: 0.74, label: :clear } }

# Check for ambiguity
client.perceptual_ambiguity
# => { ambiguity_level: 0.25, label: :low }

# Adapt priors after confirmation
client.adapt_perception(modality: :visual, correct_hypothesis_id: hyp_id)

# Tick decay
client.update_perceptual_inference
```

## Modalities

`:visual`, `:auditory`, `:somatosensory`, `:olfactory`, `:gustatory`, `:proprioceptive`, `:vestibular`

## Percept Labels

| Posterior | Label |
|---|---|
| 0.8+ | `:vivid` |
| 0.6–0.8 | `:clear` |
| 0.4–0.6 | `:ambiguous` |
| 0.2–0.4 | `:faint` |
| < 0.2 | `:subliminal` |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT

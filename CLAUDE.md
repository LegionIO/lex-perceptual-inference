# lex-perceptual-inference

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-perceptual-inference`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::PerceptualInference`

## Purpose

Bayesian perceptual inference across multiple sensory modalities. Maintains a field of competing hypotheses per modality, updates posteriors as evidence arrives, selects the dominant percept when confidence exceeds threshold, detects binocular rivalry (competing percepts of similar strength), and adapts priors based on prediction outcomes.

## Gem Info

- **Homepage**: https://github.com/LegionIO/lex-perceptual-inference
- **License**: MIT
- **Ruby**: >= 3.4

## File Structure

```
lib/legion/extensions/perceptual_inference/
  version.rb
  client.rb
  helpers/
    constants.rb               # All constants — modalities, thresholds, hypothesis states
    perceptual_hypothesis.rb   # PerceptualHypothesis — Bayesian belief with prior/likelihood/posterior
    perceptual_field.rb        # PerceptualField — per-modality hypothesis store + evidence processing
  runners/
    perceptual_inference.rb    # Runner module
spec/
  helpers/constants_spec.rb
  helpers/perceptual_hypothesis_spec.rb
  helpers/perceptual_field_spec.rb
  runners/perceptual_inference_spec.rb
  client_spec.rb
```

## Key Constants

- `MODALITIES = %i[visual auditory somatosensory olfactory gustatory proprioceptive vestibular]`
- `HYPOTHESIS_STATES = %i[active selected suppressed decayed]`
- `MAX_HYPOTHESES = 30` (per modality before pruning), `MAX_EVIDENCE = 100`
- `DEFAULT_PRIOR = 0.5`, `PRIOR_FLOOR = 0.01`, `PRIOR_CEILING = 0.99`
- `SELECTION_THRESHOLD = 0.6` — posterior must exceed this to be selected
- `RIVALRY_MARGIN = 0.1` — top-two posteriors within this margin = rivalry
- `ADAPTATION_RATE = 0.1`, `DECAY_RATE = 0.01`
- `PERCEPT_LABELS`: `:vivid` (0.8+), `:clear`, `:ambiguous`, `:faint`, `:subliminal`

## Runners

| Method | Key Parameters | Returns |
|---|---|---|
| `register_percept_hypothesis` | `content:`, `modality:`, `domain:`, `prior:` | `{ hypothesis_id:, modality:, prior: }` |
| `present_perceptual_evidence` | `modality:`, `content:`, `strength:` | `{ hypotheses_updated:, rivalry: }` |
| `select_percept` | `modality:` | `{ selected: bool, hypothesis: }` or rivalry info |
| `check_rivalry` | `modality:` | `{ rivalry: bool, top_hypotheses: }` |
| `current_percept` | `modality:` | current selected hypothesis or not found |
| `adapt_perception` | `modality:`, `correct_hypothesis_id:` | adapts all priors in modality |
| `suppress_percept` | `hypothesis_id:` | suppresses named hypothesis |
| `perceptual_ambiguity` | — | `{ ambiguity_level:, label: (:high, :moderate, :low, :none) }` |
| `update_perceptual_inference` | — | decay tick; removes decayed hypotheses |
| `perceptual_inference_stats` | — | `{ stats: field.to_h }` |

## Helpers

### `Helpers::PerceptualHypothesis`
Bayesian belief: `prior`, `likelihood`, `posterior`. `compute_posterior(evidence_weight:)` = `prior * (likelihood * weight + (1-weight) * prior)`. `select!` and `suppress!` change state. `rival_with?(other)` = posteriors within `RIVALRY_MARGIN`. `adapt_prior(outcome:)` +/- `ADAPTATION_RATE`. `decay` — suppressed hypotheses decay faster (5x); active hypotheses drift toward 0.5.

### `Helpers::PerceptualField`
Manages all hypotheses keyed by UUID. `present_evidence` updates likelihood via content-match heuristic (0.8 if content includes evidence, else 0.3), then calls `compute_posterior`. `select_percept` picks highest posterior above `SELECTION_THRESHOLD`, suppresses others. `rivalry?` compares top-two. `ambiguity_level` = rival_count / active_modality_count. Validates modality via `ArgumentError`.

## Integration Points

- `select_percept` output feeds sensory processing phases in `lex-tick`
- `perceptual_ambiguity` level can raise or lower prediction uncertainty in `lex-predictive-coding`
- `adapt_perception` called when `lex-reality-testing` resolves a belief tied to perception
- `present_perceptual_evidence` triggered by raw sensory inputs from environment

## Development Notes

- Likelihood computation is a heuristic: substring match on stringified content vs evidence content
- `rival_with?` is pairwise — only checks two hypotheses; `PerceptualField` checks the top-two candidates
- Pruning when `MAX_HYPOTHESES` exceeded: first removes suppressed/decayed; if none, removes 5 lowest-posterior active hypotheses
- State is fully in-memory; reset on process restart

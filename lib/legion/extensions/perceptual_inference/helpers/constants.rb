# frozen_string_literal: true

module Legion
  module Extensions
    module PerceptualInference
      module Helpers
        MAX_HYPOTHESES       = 30
        MAX_EVIDENCE         = 100
        MAX_HISTORY          = 200
        DEFAULT_PRIOR        = 0.5
        PRIOR_FLOOR          = 0.01
        PRIOR_CEILING        = 0.99
        SELECTION_THRESHOLD  = 0.6
        RIVALRY_MARGIN       = 0.1
        EVIDENCE_STRENGTH_FLOOR = 0.05
        ADAPTATION_RATE      = 0.1
        DECAY_RATE           = 0.01
        MODALITIES           = %i[visual auditory somatosensory olfactory gustatory proprioceptive vestibular].freeze
        HYPOTHESIS_STATES    = %i[active selected suppressed decayed].freeze
        PERCEPT_LABELS       = {
          (0.8..)     => :vivid,
          (0.6...0.8) => :clear,
          (0.4...0.6) => :ambiguous,
          (0.2...0.4) => :faint,
          (..0.2)     => :subliminal
        }.freeze
      end
    end
  end
end

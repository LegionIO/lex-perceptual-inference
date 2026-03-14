# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module PerceptualInference
      module Helpers
        class PerceptualHypothesis
          attr_reader   :id, :content, :modality, :domain, :state, :created_at
          attr_accessor :prior, :likelihood, :posterior

          def initialize(content:, modality:, domain: :general, prior: DEFAULT_PRIOR)
            @id         = SecureRandom.uuid
            @content    = content
            @modality   = modality
            @domain     = domain
            @prior      = clamp_prior(prior.to_f)
            @likelihood = 0.5
            @posterior  = @prior
            @state      = :active
            @created_at = Time.now.utc
          end

          def compute_posterior(evidence_weight:)
            weight   = [evidence_weight.to_f, EVIDENCE_STRENGTH_FLOOR].max
            raw      = @prior * ((@likelihood * weight) + ((1.0 - weight) * @prior))
            @posterior = clamp_unit(raw)
          end

          def select!
            @state = :selected
          end

          def suppress!
            @state = :suppressed
          end

          def selected?
            @state == :selected
          end

          def rival_with?(other)
            return false unless other.is_a?(PerceptualHypothesis)

            (posterior - other.posterior).abs <= RIVALRY_MARGIN
          end

          def adapt_prior(outcome:)
            delta    = outcome == :correct ? ADAPTATION_RATE : -ADAPTATION_RATE
            @prior   = clamp_prior(@prior + delta)
          end

          def decay
            if @state == :suppressed
              @prior = clamp_prior(@prior - (DECAY_RATE * 5))
              @state = :decayed if @prior <= PRIOR_FLOOR + 0.001
            else
              @prior = clamp_prior(@prior + ((DEFAULT_PRIOR - @prior) * DECAY_RATE))
            end
          end

          def percept_label
            PERCEPT_LABELS.each { |range, label| return label if range.cover?(@posterior) }
            :subliminal
          end

          def to_h
            {
              id:         @id,
              content:    @content,
              modality:   @modality,
              domain:     @domain,
              prior:      @prior.round(4),
              likelihood: @likelihood.round(4),
              posterior:  @posterior.round(4),
              state:      @state,
              label:      percept_label,
              created_at: @created_at
            }
          end

          private

          def clamp_prior(value)
            value.clamp(PRIOR_FLOOR, PRIOR_CEILING)
          end

          def clamp_unit(value)
            value.clamp(0.0, 1.0)
          end
        end
      end
    end
  end
end

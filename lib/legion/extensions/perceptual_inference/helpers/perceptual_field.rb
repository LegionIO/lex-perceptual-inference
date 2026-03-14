# frozen_string_literal: true

module Legion
  module Extensions
    module PerceptualInference
      module Helpers
        class PerceptualField
          attr_reader :hypotheses, :evidence_log

          def initialize
            @hypotheses = {}
            @evidence_log = []
          end

          def register_hypothesis(content:, modality:, domain: :general, prior: DEFAULT_PRIOR)
            validate_modality!(modality)
            prune_modality(modality) if hypotheses_for(modality).size >= MAX_HYPOTHESES

            hypothesis = PerceptualHypothesis.new(
              content:  content,
              modality: modality,
              domain:   domain,
              prior:    prior
            )
            @hypotheses[hypothesis.id] = hypothesis
            hypothesis
          end

          def present_evidence(modality:, content:, strength: 0.5)
            validate_modality!(modality)
            strength = [strength.to_f, EVIDENCE_STRENGTH_FLOOR].max
            record_evidence(modality, content, strength)

            active_hypotheses_for(modality).each do |h|
              h.likelihood = compute_likelihood(h, content, strength)
              h.compute_posterior(evidence_weight: strength)
            end

            hypotheses_for(modality).size
          end

          def select_percept(modality:)
            validate_modality!(modality)
            candidates = active_hypotheses_for(modality)
            return nil if candidates.empty?

            winner = candidates.max_by(&:posterior)
            return nil if winner.posterior < SELECTION_THRESHOLD

            candidates.each { |h| h.id == winner.id ? h.select! : h.suppress! }
            winner
          end

          def rivalry?(modality:)
            validate_modality!(modality)
            candidates = active_hypotheses_for(modality)
            return false if candidates.size < 2

            top_two = candidates.max_by(2, &:posterior)
            top_two.first.rival_with?(top_two.last)
          end

          def current_percept(modality:)
            validate_modality!(modality)
            @hypotheses.values.find { |h| h.modality == modality && h.state == :selected }
          end

          def hypotheses_for(modality)
            @hypotheses.values.select { |h| h.modality == modality }
          end

          def suppress_hypothesis(hypothesis_id:)
            h = @hypotheses[hypothesis_id]
            return false unless h

            h.suppress!
            true
          end

          def adapt_priors(modality:, correct_hypothesis_id:)
            validate_modality!(modality)
            hypotheses_for(modality).each do |h|
              outcome = h.id == correct_hypothesis_id ? :correct : :incorrect
              h.adapt_prior(outcome: outcome)
            end
          end

          def ambiguity_level
            rival_count = MODALITIES.count { |m| rivalry?(modality: m) && hypotheses_for(m).any? }
            total_active = MODALITIES.count { |m| hypotheses_for(m).any? }
            return 0.0 if total_active.zero?

            rival_count.to_f / total_active
          end

          def decay_all
            @hypotheses.each_value(&:decay)
            @hypotheses.reject! { |_, h| h.state == :decayed }
          end

          def to_h
            by_modality = MODALITIES.each_with_object({}) do |m, acc|
              hs = hypotheses_for(m)
              next if hs.empty?

              acc[m] = {
                count:   hs.size,
                rivalry: rivalry?(modality: m),
                percept: current_percept(modality: m)&.to_h
              }
            end

            {
              hypotheses_total: @hypotheses.size,
              ambiguity_level:  ambiguity_level.round(4),
              by_modality:      by_modality
            }
          end

          private

          def active_hypotheses_for(modality)
            @hypotheses.values.select { |h| h.modality == modality && %i[active selected].include?(h.state) }
          end

          def compute_likelihood(hypothesis, evidence_content, strength)
            base = hypothesis.content.to_s.downcase.include?(evidence_content.to_s.downcase) ? 0.8 : 0.3
            [(base * strength) + (hypothesis.likelihood * (1.0 - strength)), 1.0].min
          end

          def record_evidence(modality, content, strength)
            entry = { modality: modality, content: content, strength: strength, at: Time.now.utc }
            @evidence_log << entry
            @evidence_log.shift while @evidence_log.size > MAX_EVIDENCE
          end

          def prune_modality(modality)
            candidates = hypotheses_for(modality).select { |h| %i[suppressed decayed].include?(h.state) }
            candidates = hypotheses_for(modality).min_by(5, &:posterior) if candidates.empty?
            candidates.each { |h| @hypotheses.delete(h.id) }
          end

          def validate_modality!(modality)
            raise ArgumentError, "Unknown modality: #{modality}" unless MODALITIES.include?(modality)
          end
        end
      end
    end
  end
end

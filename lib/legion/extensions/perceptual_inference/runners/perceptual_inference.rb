# frozen_string_literal: true

module Legion
  module Extensions
    module PerceptualInference
      module Runners
        module PerceptualInference
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def register_percept_hypothesis(content:, modality:, domain: :general, prior: Helpers::DEFAULT_PRIOR, **)
            hypothesis = field.register_hypothesis(content: content, modality: modality, domain: domain, prior: prior)
            Legion::Logging.debug "[perceptual_inference] registered hypothesis modality=#{modality} id=#{hypothesis.id[0..7]}"
            { success: true, hypothesis_id: hypothesis.id, modality: modality, prior: hypothesis.prior }
          rescue ArgumentError => e
            Legion::Logging.warn "[perceptual_inference] register failed: #{e.message}"
            { success: false, error: e.message }
          end

          def present_perceptual_evidence(modality:, content:, strength: 0.5, **)
            count = field.present_evidence(modality: modality, content: content, strength: strength)
            Legion::Logging.debug "[perceptual_inference] evidence presented modality=#{modality} strength=#{strength} updated=#{count}"
            { success: true, modality: modality, hypotheses_updated: count, rivalry: field.rivalry?(modality: modality) }
          rescue ArgumentError => e
            Legion::Logging.warn "[perceptual_inference] evidence failed: #{e.message}"
            { success: false, error: e.message }
          end

          def select_percept(modality:, **)
            winner = field.select_percept(modality: modality)
            if winner
              Legion::Logging.info "[perceptual_inference] percept selected modality=#{modality} " \
                                   "posterior=#{winner.posterior.round(3)} label=#{winner.percept_label}"
              { success: true, selected: true, hypothesis: winner.to_h }
            else
              rivalry = field.rivalry?(modality: modality)
              Legion::Logging.debug "[perceptual_inference] no percept selected modality=#{modality} rivalry=#{rivalry}"
              { success: true, selected: false, rivalry: rivalry }
            end
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def check_rivalry(modality:, **)
            rival = field.rivalry?(modality: modality)
            candidates = field.hypotheses_for(modality)
            top_two    = candidates.select { |h| %i[active selected].include?(h.state) }.max_by(2, &:posterior)
            Legion::Logging.debug "[perceptual_inference] rivalry check modality=#{modality} rival=#{rival}"
            { success: true, rivalry: rival, modality: modality, top_hypotheses: top_two.map(&:to_h) }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def current_percept(modality:, **)
            percept = field.current_percept(modality: modality)
            if percept
              { success: true, found: true, modality: modality, percept: percept.to_h }
            else
              { success: true, found: false, modality: modality }
            end
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def adapt_perception(modality:, correct_hypothesis_id:, **)
            field.adapt_priors(modality: modality, correct_hypothesis_id: correct_hypothesis_id)
            Legion::Logging.info "[perceptual_inference] priors adapted modality=#{modality} correct=#{correct_hypothesis_id[0..7]}"
            { success: true, modality: modality, correct_hypothesis_id: correct_hypothesis_id }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def suppress_percept(hypothesis_id:, **)
            suppressed = field.suppress_hypothesis(hypothesis_id: hypothesis_id)
            Legion::Logging.debug "[perceptual_inference] suppress hypothesis_id=#{hypothesis_id[0..7]} result=#{suppressed}"
            { success: true, suppressed: suppressed, hypothesis_id: hypothesis_id }
          end

          def perceptual_ambiguity(**)
            level = field.ambiguity_level
            label = ambiguity_label(level)
            Legion::Logging.debug "[perceptual_inference] ambiguity=#{level.round(3)} label=#{label}"
            { success: true, ambiguity_level: level, label: label }
          end

          def update_perceptual_inference(**)
            field.decay_all
            Legion::Logging.debug "[perceptual_inference] decay cycle complete remaining=#{field.hypotheses.size}"
            { success: true, remaining_hypotheses: field.hypotheses.size }
          end

          def perceptual_inference_stats(**)
            { success: true, stats: field.to_h }
          end

          private

          def field
            @field ||= Helpers::PerceptualField.new
          end

          def ambiguity_label(level)
            if level >= 0.75
              :high
            elsif level >= 0.4
              :moderate
            elsif level.positive?
              :low
            else
              :none
            end
          end
        end
      end
    end
  end
end

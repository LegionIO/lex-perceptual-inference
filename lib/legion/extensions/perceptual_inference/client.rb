# frozen_string_literal: true

require 'legion/extensions/perceptual_inference/helpers/constants'
require 'legion/extensions/perceptual_inference/helpers/perceptual_hypothesis'
require 'legion/extensions/perceptual_inference/helpers/perceptual_field'
require 'legion/extensions/perceptual_inference/runners/perceptual_inference'

module Legion
  module Extensions
    module PerceptualInference
      class Client
        include Runners::PerceptualInference

        def initialize(field: nil, **)
          @field = field || Helpers::PerceptualField.new
        end

        private

        attr_reader :field
      end
    end
  end
end

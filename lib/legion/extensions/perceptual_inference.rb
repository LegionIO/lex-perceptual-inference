# frozen_string_literal: true

require 'legion/extensions/perceptual_inference/version'
require 'legion/extensions/perceptual_inference/helpers/constants'
require 'legion/extensions/perceptual_inference/helpers/perceptual_hypothesis'
require 'legion/extensions/perceptual_inference/helpers/perceptual_field'
require 'legion/extensions/perceptual_inference/runners/perceptual_inference'

module Legion
  module Extensions
    module PerceptualInference
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end

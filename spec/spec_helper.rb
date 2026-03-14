# frozen_string_literal: true

require 'bundler/setup'

require 'legion/extensions/perceptual_inference/version'
require 'legion/extensions/perceptual_inference/helpers/constants'
require 'legion/extensions/perceptual_inference/helpers/perceptual_hypothesis'
require 'legion/extensions/perceptual_inference/helpers/perceptual_field'
require 'legion/extensions/perceptual_inference/runners/perceptual_inference'
require 'legion/extensions/perceptual_inference/client'

module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

module Legion
  module Logging
    def self.debug(_msg); end
    def self.info(_msg); end
    def self.warn(_msg); end
    def self.error(_msg); end
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end

require File.expand_path('../../lib/pipefitter.rb', __FILE__)
require 'fileutils' 
require 'logger'
require 'pry'

class Pipefitter
  module SpecHelper
    private
    
    def stub_rails_app(base_working_directory, options = {})
      if options[:destroy_initially]
        FileUtils.rm_rf(base_working_directory)
      end
      FileUtils.mkdir_p(base_working_directory)
      app_source_path = File.expand_path('../support/stubbed_rails_app', __FILE__)
      FileUtils.cp_r(app_source_path, base_working_directory)
    end

    def null_logger
      @null_logger ||= ::Logger.new('/dev/null')
    end
  end
end

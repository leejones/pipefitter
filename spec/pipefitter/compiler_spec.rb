require File.expand_path('../../spec_helper.rb', __FILE__)
require 'logger'

describe Pipefitter::Compiler do
  include Pipefitter::SpecHelper

  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
  end

  it 'compiles assets' do
    compiler = Pipefitter::Compiler.new(rails_root, :logger => null_logger)
    compiler.compile
    File.exists?("#{rails_root}/public/assets/manifest.yml").should be_true
  end
end

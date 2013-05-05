require File.expand_path('../../spec_helper.rb', __FILE__)

describe Pipefitter::Checksum do
  include Pipefitter::SpecHelper

  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
  end

  it 'checksums a group of files and directories' do
    paths = %w{
      Gemfile
      Gemfile.lock
      app/assets
      lib/assets
      vendor/assets
    }.map { |p| File.join(rails_root, p) }
    checksum = Pipefitter::Checksum.new(paths)
    checksum.checksum.should eql('1146bbf7a93640fc4054defc8be871e7')
  end
end

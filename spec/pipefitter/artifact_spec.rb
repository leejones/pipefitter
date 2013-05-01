require 'spec_helper'

describe Pipefitter::Artifact do
  include Pipefitter::SpecHelper
  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
    FileUtils.mkdir(assets_path)
    %w{a b c}.each { |f| FileUtils.touch(File.join(assets_path, "#{f}.css")) }
    system "tar -C #{rails_root}/public -czf #{artifact_path} assets"
  end

  let(:artifact_path) { File.join(test_root, 'artifact.tar.gz') }
  let(:artifact_checksum) { 'abc-123-checksum' }
  let(:assets_path) { File.join(rails_root, 'public', 'assets') }
  let(:artifact) { Pipefitter::Artifact.new(artifact_path, artifact_checksum) }

  subject { Pipefitter::Artifact.new(artifact_path, artifact_checksum) }

  it 'has a path' do
    subject.path.should eql(artifact_path)
  end

  it 'has a checksum' do
    subject.checksum.should eql(artifact_checksum)
  end

  it 'expands to a path' do
    expander_stub = stub
    Pipefitter::Artifact::Expander.should_receive(:new).with(subject).and_return(expander_stub)
    expander_stub.should_receive(:expand_to).with(File.join(rails_root, 'public'))
    subject.expand_to(File.join(rails_root, 'public'))
  end

  describe Pipefitter::Artifact::Expander do
    before(:each) { FileUtils.rm_rf(assets_path) }
    subject { Pipefitter::Artifact::Expander.new(artifact) }

    it 'expands archives to a path' do
      subject.expand_to(File.join(rails_root, 'public'))
      Dir.glob(File.join(rails_root, 'public', 'assets', '*')).map do |path|
        path.split('/').last
      end.should eql(%w{a.css b.css c.css})
    end

    it 'verifies the checksum of the expanded archive'
    it 'raises an error if checksum does not match expanded archive'
  end

  describe Pipefitter::Artifact::Compressor do
    subject { Pipefitter::Artifact::Compressor.new(assets_path) }
    let(:compressed_artifacts_path) do
      path = File.join(test_root, 'artifacts')
      FileUtils.mkdir_p(path)
      path
    end

    it 'compresses artifacts' do
      subject.compress_to(File.join(compressed_artifacts_path, 'result.tar.gz'))
      Dir.glob("#{compressed_artifacts_path}/*").should eql([File.join(compressed_artifacts_path, 'result.tar.gz')])
    end

    it 'stores a checksum of the artifact'
  end
end

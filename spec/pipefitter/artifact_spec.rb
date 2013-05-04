require 'spec_helper'

describe Pipefitter::Artifact do
  include Pipefitter::SpecHelper

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
    FileUtils.mkdir(assets_path)
    %w{a b c}.each { |f| FileUtils.touch(File.join(assets_path, "#{f}.css")) }
    system "tar -C #{public_path} -czf #{artifact_path} assets"
  end

  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }
  let(:artifact_path) { File.join(test_root, 'artifact.tar.gz') }
  let(:artifact_checksum) { 'abc-123-checksum' }
  let(:public_path) { File.join(rails_root, 'public') }
  let(:assets_path) { File.join(public_path, 'assets') }
  let(:artifact) { Pipefitter::Artifact.new(artifact_path, artifact_checksum) }

  subject { Pipefitter::Artifact.new(artifact_path, artifact_checksum) }

  it 'has a path' do
    subject.path.should eql(artifact_path)
  end

  it 'has a checksum' do
    subject.checksum.should eql(artifact_checksum)
  end

  describe 'expand_to' do
    before(:each) { FileUtils.rm_rf(assets_path) }

    it 'expands to a path' do
      subject.expand_to(public_path)
      Dir.glob(File.join(rails_root, 'public', 'assets', '*')).map do |path|
        path.split('/').last
      end.should eql(%w{a.css b.css c.css})
    end
  end

  describe 'verify_expansion' do
    it 'returns true if checksums match' do
      subject.expand_to(public_path)
      Pipefitter::Checksum.should_receive(:checksum).with(assets_path).and_return(artifact_checksum)
      subject.verify_expansion(assets_path).should be_true
    end

    it 'returns false if checksums do not match' do
      subject.expand_to(public_path)
      Pipefitter::Checksum.should_receive(:checksum).with(assets_path).and_return('foo-bar-checksum')
      subject.verify_expansion(assets_path).should be_false
    end
  end

  describe 'create' do
    subject { Pipefitter::Artifact.create(assets_path, artifact_path) }

    it 'returns an artifact instance' do
      subject.path.should eql(artifact_path)
      subject.checksum.should eql(Pipefitter::Checksum.checksum(assets_path))
    end

    it 'stores the artifact' do
      File.exists?(subject.path).should be_true
    end

    it 'stores a checksum of the artifact' do
      File.exists?("#{subject.path}.md5").should be_true
    end
  end
end

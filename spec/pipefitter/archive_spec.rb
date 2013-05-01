require 'spec_helper'

describe Pipefitter::Archive do
  include Pipefitter::SpecHelper
  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }
  let(:archive_path) { File.join(rails_root, 'tmp', 'pipefitter', 'archive') }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
  end

  subject { Pipefitter::Archive.new(archive_path) }

  it 'creates an archive directory' do
    File.directory?(archive_path)
  end

  it 'gets an archived item by key' do
    FileUtils.mkdir_p(archive_path)
    FileUtils.touch(File.join(archive_path, '1365740400-abcd.tar.gz'))
    FileUtils.touch(File.join(archive_path, '1365740400-abcd.md5'))
    subject.get('abcd').should be_a(Pipefitter::Artifact)
  end

  it 'stores archived items with a timestamped key' do
    Time.should_receive(:now).and_return(stub(:to_i => 1365740400))
    path_to_archive = File.join(rails_root, 'public')
    Pipefitter::Artifact.should_receive(:create).with(path_to_archive, '1365740400-abcd').and_return(true)
    subject.put(path_to_archive, 'abcd')
  end

  it 'keeps the 3 most recent artifacts by default' do
    FileUtils.mkdir_p(archive_path)
    5.times do |n|
      FileUtils.touch(File.join(archive_path, "136574040#{n}-abcd.tar.gz"))
      FileUtils.touch(File.join(archive_path, "136574040#{n}-abcd.md5"))
    end
    subject.purge
    Dir.glob(File.join(archive_path, '*.tar.gz')).count.should eql(3)
    Dir.glob(File.join(archive_path, '*.md5')).count.should eql(3)
  end
end

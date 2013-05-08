require File.expand_path('../spec_helper.rb', __FILE__)
require 'yaml'

describe Pipefitter do
  include Pipefitter::SpecHelper

  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }
  let(:archive_root) { File.join(rails_root, 'tmp', 'pipefitter', 'archive') }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
  end

  it 'compiles assets' do
    Pipefitter.compile(rails_root, :logger => null_logger)
    manifest_file = "#{rails_root}/public/assets/manifest.yml"
    File.exists?(manifest_file).should be_true
  end

  it 'archives a compile' do
    Time.any_instance.stub(:to_i).and_return(1367981806)
    Pipefitter.compile(rails_root, :logger => null_logger)
    File.exists?(File.join(archive_root, '1367981806-63af33df99e1f88bff6d3696f4ae6686.tar.gz')).should be_true
    File.exists?(File.join(archive_root, '1367981806-63af33df99e1f88bff6d3696f4ae6686.md5')).should be_true
  end

  it 'stores an archived copy of compiled assets' do
    Time.any_instance.stub(:to_i).and_return(1367981555)
    Pipefitter.compile(rails_root, :logger => null_logger)
    archive_file = File.join(archive_root, '1367981555-63af33df99e1f88bff6d3696f4ae6686.tar.gz')
    checksum_file = File.join(archive_root, '1367981555-63af33df99e1f88bff6d3696f4ae6686.md5')
    File.exists?(archive_file).should be_true
    `cd #{test_root} && tar -xzf #{archive_file}`
    archived_assets_checksum = `find #{test_root}/assets -type f -exec md5 -q {} + | md5 -q`.strip
    compiled_assets_checksum = `find #{rails_root}/public/assets -type f -exec md5 -q {} + | md5 -q`.strip
    archived_assets_checksum.should eql(compiled_assets_checksum)
    archived_assets_checksum.should eql(File.read(checksum_file))
  end

  it 'uses an archived copy of compiled assets when available' do
    Pipefitter.compile(rails_root, :logger => null_logger)
    original_checksum = Pipefitter::Checksum.new("#{rails_root}/public/assets").checksum
    FileUtils.rm_rf("#{rails_root}/public/assets/manifest.yml")
    compiler_stub = stub
    Pipefitter::Compiler.stub(:new => compiler_stub)
    compiler_stub.should_not_receive(:compile)
    Pipefitter.compile(rails_root, :archive => true, :logger => null_logger)
    final_checksum = Pipefitter::Checksum.new("#{rails_root}/public/assets").checksum
    final_checksum.should eql(original_checksum)
  end

  it 'only compiles when needed' do
    FileUtils.mkdir_p(archive_root)
    FileUtils.touch(File.join(archive_root, '1234567-1146bbf7a93640fc4054defc8be871e7.tar.gz'))
    checksum_file_path = File.join(archive_root, '1234567-1146bbf7a93640fc4054defc8be871e7.md5')
    File.open(checksum_file_path, 'w+') do |file|
      file.write 'd41d8cd98f00b204e9800998ecf8427e'
    end
    compiler_stub = stub
    Pipefitter::Compiler.stub(:new => compiler_stub)
    compiler_stub.should_not_receive(:compile)
    Pipefitter.compile(rails_root, :logger => null_logger)
  end

  it 'does not record a checksum if the compile fails' do
    FileUtils.rm("#{rails_root}/Rakefile")
    expect { Pipefitter.compile(rails_root, :logger => null_logger) }.to raise_error(Pipefitter::CompilationError)
    File.exists?("#{rails_root}/tmp/pipefitter/checksum.txt").should be_false
  end

  it 'forces a compile' do
    Pipefitter.compile(rails_root, :logger => null_logger)
    compiler_stub = stub
    Pipefitter::Compiler.stub(:new => compiler_stub)
    compiler_stub.should_receive(:compile).and_return(true)
    Pipefitter.compile(rails_root, :force => true, :logger => null_logger)
  end

  it 'uses a custom compile command' do
    compiler_stub = stub
    Pipefitter::Compiler.should_receive(:new).with(rails_root, :logger => kind_of(Logger), :command => 'script/precompile_assets').and_return(compiler_stub)
    compiler_stub.should_receive(:compile).and_return(true)
    Pipefitter.compile(rails_root, :command => 'script/precompile_assets', :logger => null_logger)
  end

  it 'skips optional directories if they do not exist' do
    FileUtils.rm_r(File.join(rails_root, 'lib/assets'))
    FileUtils.rm_r(File.join(rails_root, 'vendor/assets'))
    Pipefitter.compile(rails_root, :logger => null_logger)
    manifest_file = "#{rails_root}/public/assets/manifest.yml"
    File.exists?(manifest_file).should be_true
  end
end

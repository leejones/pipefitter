require File.expand_path('../spec_helper.rb', __FILE__)
require 'yaml'

describe Pipefitter do
  include Pipefitter::SpecHelper

  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
  end

  it 'compiles asstets' do
    Pipefitter.compile(rails_root, :logger => null_logger)
    manifest_file = "#{rails_root}/public/assets/manifest.yml"
    File.exists?(manifest_file).should be_true
  end

  it 'records a checksum' do
    Pipefitter.compile(rails_root, :logger => null_logger)
    inventory_file = "#{rails_root}/tmp/pipefitter/inventory.yml"
    checksums = YAML.load_file(inventory_file)
    checksums.has_key?('63af33df99e1f88bff6d3696f4ae6686').should be_true
  end

  it 'stores an archived copy of compiled assets' do
    Pipefitter.compile(rails_root, :archive => true, :logger => null_logger)
    archive_file = "#{rails_root}/tmp/pipefitter/63af33df99e1f88bff6d3696f4ae6686.tar.gz"
    File.exists?(archive_file).should be_true
    `cd #{test_root} && tar -xzf #{archive_file}`
    archived_assets_checksum = `find #{test_root}/assets -type f -exec md5 -q {} + | md5 -q`.strip
    compiled_assets_checksum = `find #{rails_root}/public/assets -type f -exec md5 -q {} + | md5 -q`.strip
    archived_assets_checksum.should eql(compiled_assets_checksum)
  end

  it 'uses an archived copy of compiled assets when available' do
    Pipefitter.compile(rails_root, :archive => true, :logger => null_logger)
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
    FileUtils.mkdir_p("#{rails_root}/tmp/pipefitter")
    File.open("#{rails_root}/tmp/pipefitter/inventory.yml", 'w+') do |file|
      file.write({
        '63af33df99e1f88bff6d3696f4ae6686' => 'd41d8cd98f00b204e9800998ecf8427e'
      }.to_yaml)
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
end

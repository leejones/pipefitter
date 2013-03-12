require File.expand_path('../../lib/pipefitter.rb', __FILE__)
require 'fileutils' 
require 'yaml'

describe Pipefitter do
  before(:each) do
    stub_rails_app
  end

  describe Pipefitter do
    it 'compiles asstets' do
      Pipefitter.compile('/tmp/pipefitter_tests/stubbed_rails_app')
      File.exists?('/tmp/pipefitter_tests/stubbed_rails_app/public/assets/manifest.yml').should be_true
    end

    it 'records a checksum' do
      Pipefitter.compile('/tmp/pipefitter_tests/stubbed_rails_app')
      checksums = YAML.load_file('/tmp/pipefitter_tests/stubbed_rails_app/tmp/pipefitter/inventory.yml')
      checksums.has_key?('63af33df99e1f88bff6d3696f4ae6686').should be_true
    end

    it 'stores a compressed copy of the compiled assets' do
      Pipefitter.compile('/tmp/pipefitter_tests/stubbed_rails_app', :archive => true)
      File.exists?('/tmp/pipefitter_tests/stubbed_rails_app/tmp/pipefitter/63af33df99e1f88bff6d3696f4ae6686.tar.gz').should be_true
      `cd /tmp/pipefitter_tests && tar -xzf /tmp/pipefitter_tests/stubbed_rails_app/tmp/pipefitter/63af33df99e1f88bff6d3696f4ae6686.tar.gz`
      `find /tmp/pipefitter_tests/assets -type f -exec md5 -q {} + | md5 -q`.strip.should eql(`find /tmp/pipefitter_tests/stubbed_rails_app/public/assets -type f -exec md5 -q {} + | md5 -q`.strip)
    end

    it 'only compiles when needed' do
      FileUtils.mkdir_p('/tmp/pipefitter_tests/stubbed_rails_app/tmp/pipefitter')
      File.open('/tmp/pipefitter_tests/stubbed_rails_app/tmp/pipefitter/inventory.yml', 'w+') do |file|
        file.write({
          '63af33df99e1f88bff6d3696f4ae6686' => 'd41d8cd98f00b204e9800998ecf8427e'
        }.to_yaml)
      end
      compiler_stub = stub
      Pipefitter::Compiler.stub(:new => compiler_stub)
      compiler_stub.should_not_receive(:compile)
      Pipefitter.compile('/tmp/pipefitter_tests/stubbed_rails_app')
    end

    it 'does not record a checksum if the compile fails' do
      FileUtils.rm('/tmp/pipefitter_tests/stubbed_rails_app/Rakefile')
      expect { Pipefitter.compile('/tmp/pipefitter_tests/stubbed_rails_app') }.to raise_error(Pipefitter::CompilationError)
      File.exists?('/tmp/pipefitter_tests/stubbed_rails_app/tmp/pipefitter/checksum.txt').should be_false
    end
  end

  describe Pipefitter::Compiler do
    it 'compiles asstets' do
      compiler = Pipefitter::Compiler.new('/tmp/pipefitter_tests/stubbed_rails_app')
      compiler.compile
      File.exists?('/tmp/pipefitter_tests/stubbed_rails_app/public/assets/manifest.yml').should be_true
    end
  end

  describe Pipefitter::Checksum do
    it 'checksums a group of files and directories' do
      paths = %w{
        Gemfile
        Gemfile.lock
        app/assets
        lib/assets
        vendor/assets
      }.map { |p| File.join('/tmp/pipefitter_tests/stubbed_rails_app', p) }
      checksum = Pipefitter::Checksum.new(paths)
      checksum.checksum.should eql('63af33df99e1f88bff6d3696f4ae6686')
    end
  end

  private
  
  def stub_rails_app
    FileUtils.rm_rf('/tmp/pipefitter_tests')
    FileUtils.mkdir_p('/tmp/pipefitter_tests')
    FileUtils.cp_r(File.expand_path('../support/stubbed_rails_app', __FILE__), '/tmp/pipefitter_tests')
  end
end

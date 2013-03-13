require File.expand_path('../../lib/pipefitter.rb', __FILE__)
require 'fileutils' 
require 'yaml'

describe Pipefitter do
  let(:test_root) { '/tmp/pipefitter_tests' }
  let(:rails_root) { "#{test_root}/stubbed_rails_app" }

  before(:each) do
    stub_rails_app(test_root, :destroy_initially => true)
  end

  describe Pipefitter do
    it 'compiles asstets' do
      Pipefitter.compile(rails_root)
      manifest_file = "#{rails_root}/public/assets/manifest.yml"
      File.exists?(manifest_file).should be_true
    end

    it 'records a checksum' do
      Pipefitter.compile(rails_root)
      inventory_file = "#{rails_root}/tmp/pipefitter/inventory.yml"
      checksums = YAML.load_file(inventory_file)
      checksums.has_key?('63af33df99e1f88bff6d3696f4ae6686').should be_true
    end

    it 'stores a compressed copy of the compiled assets' do
      Pipefitter.compile(rails_root, :archive => true)
      archive_file = "#{rails_root}/tmp/pipefitter/63af33df99e1f88bff6d3696f4ae6686.tar.gz"
      File.exists?(archive_file).should be_true
      `cd #{test_root} && tar -xzf #{archive_file}`
      archived_assets_checksum = `find #{test_root}/assets -type f -exec md5 -q {} + | md5 -q`.strip
      compiled_assets_checksum = `find #{rails_root}/public/assets -type f -exec md5 -q {} + | md5 -q`.strip
      archived_assets_checksum.should eql(compiled_assets_checksum)
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
      Pipefitter.compile(rails_root)
    end

    it 'does not record a checksum if the compile fails' do
      FileUtils.rm("#{rails_root}/Rakefile")
      expect { Pipefitter.compile(rails_root) }.to raise_error(Pipefitter::CompilationError)
      File.exists?("#{rails_root}/tmp/pipefitter/checksum.txt").should be_false
    end
  end

  describe Pipefitter::Compiler do
    it 'compiles asstets' do
      compiler = Pipefitter::Compiler.new(rails_root)
      compiler.compile
      File.exists?("#{rails_root}/public/assets/manifest.yml").should be_true
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
      }.map { |p| File.join(rails_root, p) }
      checksum = Pipefitter::Checksum.new(paths)
      checksum.checksum.should eql('63af33df99e1f88bff6d3696f4ae6686')
    end
  end

  private
  
  def stub_rails_app(base_working_directory, options = {})
    if options[:destroy_initially]
      FileUtils.rm_rf(base_working_directory)
    end
    FileUtils.mkdir_p(base_working_directory)
    app_source_path = File.expand_path('../support/stubbed_rails_app', __FILE__)
    FileUtils.cp_r(app_source_path, base_working_directory)
  end
end

require 'pipefitter/version'
require 'fileutils'

class Pipefitter
  autoload 'Compiler', 'pipefitter/compiler'
  autoload 'Checksum', 'pipefitter/checksum'
  autoload 'Compressor', 'pipefitter/compressor'
  autoload 'Inventory', 'pipefitter/inventory'
  autoload 'Error', 'pipefitter/error'

  attr_reader :base_path

  def initialize(base_path, options = {})
    @base_path = base_path
    @archive = options.fetch(:archive, true)
  end

  def compile
    setup
    if assets_need_compiling?
      compile_and_record_checksum
      archive
    end
  end

  def self.compile(base_path)
    Pipefitter.new(base_path).compile
  end

  def source_checksum
    Checksum.checksum(source_paths)
  end

  def artifact_checksum
    Checksum.checksum(artifact_paths)
  end

  private

  def compile_and_record_checksum
    if compiler.compile
      inventory.put(source_checksum, artifact_checksum)
    else
      raise CompilationError
    end
  end

  def archive
    if archiving_enabled?
      compressor.compress("#{source_checksum}.tar.gz")
    end
  end

  def compiler
    @compiler ||= Compiler.new(base_path)
  end

  def compressor
    @compressor ||= Compressor.new(base_path)
  end

  def inventory
    @inventory ||= Inventory.new(workspace)
  end

  def assets_need_compiling?
    inventory.get(source_checksum) != artifact_checksum
  end

  def archiving_enabled?
    @archive
  end

  def workspace
    File.join(base_path, 'tmp', 'pipefitter')
  end

  def setup
    FileUtils.mkdir_p(workspace)
    FileUtils.mkdir_p(File.join(base_path, 'public', 'assets'))
  end

  def source_paths
    paths = %w{
      Gemfile
      Gemfile.lock
      app/assets
      lib/assets
      vendor/assets
    }.map { |p| File.join(base_path, p) }
  end

  def artifact_paths
    %w{
      public/assets
    }.map { |p| File.join(base_path, p) }
  end

  class CompilationError < Pipefitter::Error; end
end

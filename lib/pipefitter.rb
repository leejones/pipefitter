require 'pipefitter/version'
require 'fileutils'

class Pipefitter
  autoload 'Compiler', 'pipefitter/compiler'
  autoload 'Checksum', 'pipefitter/checksum'
  autoload 'Compressor', 'pipefitter/compressor'
  autoload 'Inventory', 'pipefitter/inventory'
  autoload 'Error', 'pipefitter/error'

  attr_reader :base_path

  def self.compile(base_path, options = {})
    new(base_path, options).compile
  end

  def initialize(base_path, options = {})
    @base_path = base_path
    @archive = options.fetch(:archive, false)
  end

  def compile
    setup
    if inventory_contains_compiled_assets?
      move_archived_assets_into_place
    elsif assets_need_compiling?
      compile_and_record_checksum
      archive
    end
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
    artifact_paths.each { |path| FileUtils.mkdir_p(path) }
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

  def inventory_contains_compiled_assets?
    inventory_path = File.join(workspace, "#{source_checksum}.tar.gz")
    inventory.get(source_checksum) && File.exists?(inventory_path)
  end

  def move_archived_assets_into_place
    inventory_path = File.join(workspace, "#{source_checksum}.tar.gz")
    FileUtils.rm_rf("#{base_path}/public/assets")
    `cd #{base_path}/public && tar -xzf #{inventory_path}`
    expected_artifact_checksum = inventory.get(source_checksum)
    if expected_artifact_checksum != artifact_checksum
      raise CompilationError, 'Archived assets did match stored checksum!'
    end
  end

  class CompilationError < Pipefitter::Error; end
end

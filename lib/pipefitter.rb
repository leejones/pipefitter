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
    @options = options
  end

  def compile
    setup
    compile_if_necessary
  end

  def source_checksum
    Checksum.checksum(source_paths)
  end

  def artifact_checksum
    Checksum.checksum(artifact_paths)
  end

  private

  def compile_if_necessary
    if assets_need_compiling?
      use_archive_or_compile
    end
  end

  def use_archive_or_compile
    if inventory_can_be_used?
      move_archived_assets_into_place
    else
      compile_and_record_checksum
      archive
    end
  end

  def compile_and_record_checksum
    if compiler.compile
      inventory.put(source_checksum, artifact_checksum)
    else
      raise CompilationError
    end
  end

  def inventory_can_be_used?
    ! compile_forced? && inventory_contains_compiled_assets?
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
    compile_forced? || inventory.get(source_checksum) != artifact_checksum
  end

  def archiving_enabled?
    @archiving_enabled ||= options.fetch(:archive, false)
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

  def compile_forced?
    options.fetch(:force, false)
  end

  def options
    @options
  end

  class CompilationError < Pipefitter::Error; end
end

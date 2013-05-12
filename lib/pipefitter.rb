lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pipefitter/version'
require 'fileutils'

class Pipefitter
  autoload 'Compiler', 'pipefitter/compiler'
  autoload 'Checksum', 'pipefitter/checksum'
  autoload 'Cli', 'pipefitter/cli'
  autoload 'Compressor', 'pipefitter/compressor'
  autoload 'Archive', 'pipefitter/archive'
  autoload 'Artifact', 'pipefitter/artifact'
  autoload 'Error', 'pipefitter/error'
  autoload 'Logger', 'pipefitter/logger'

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

  attr_reader :options

  def compile_if_necessary
    if assets_need_compiling?
      use_archive_or_compile
    else
      logger.info 'Skipped compile because no changes were detected.'
    end
  end

  def use_archive_or_compile
    if archive_can_be_used?
      move_archived_assets_into_place
      logger.info 'Used compiled assests from local archive!'
    else
      compile!
      logger.info 'Finished compiling assets!'
      archive!
    end
  end

  def compile!
    compiler.compile or raise CompilationError
  end

  def archive_can_be_used?
    ! compile_forced? && archive_contains_compiled_assets?
  end

  def archive!
    logger.info 'Started archiving assets...'
    result = archive.put(File.join(base_path, 'public', 'assets'), source_checksum)
    archive.purge
    logger.info 'Finished archiving assets!'
    result
  end

  def compiler
    @compiler ||= Compiler.new(base_path,
      :logger => logger,
      :command => options[:command]
    )
  end

  def archive
    @archive ||= Archive.new(
      File.join(workspace, 'archive'),
      :logger => logger,
      :limit => 5
    )
  end

  def assets_need_compiling?
    compile_forced? || ! archive_contains_compiled_assets? || (archive_contains_compiled_assets? && archive.get(source_checksum).checksum != artifact_checksum)
  end

  def workspace
    File.join(base_path, 'tmp', 'pipefitter')
  end

  def setup
    FileUtils.mkdir_p(workspace)
    artifact_paths.each { |path| FileUtils.mkdir_p(path) }
  end

  def source_paths
    standard_paths | optional_paths
  end

  def standard_paths
    %w{
      Gemfile
      Gemfile.lock
      app/assets
    }.map { |path| File.join(base_path, path) }
  end

  def optional_paths
    %w{
      lib/assets
      vendor/assets
    }.map do |path|
      File.join(base_path, path)
    end.select do |path|
      File.exists?(path)
    end
  end

  def artifact_paths
    %w{
      public/assets
    }.map { |p| File.join(base_path, p) }
  end

  def archive_contains_compiled_assets?
    archive.get(source_checksum) != nil
  end

  def move_archived_assets_into_place
    archive.get(source_checksum).expand_to(File.join(base_path, 'public'))
  end

  def compile_forced?
    options.fetch(:force, false)
  end

  def logger
    @logger ||= options.fetch(:logger, Pipefitter::Logger.new)
  end

  class CompilationError < Pipefitter::Error; end
end

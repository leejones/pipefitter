require 'pipefitter/version'
require 'fileutils'

class Pipefitter
  autoload 'Compiler', 'pipefitter/compiler'
  autoload 'Checksum', 'pipefitter/checksum'
  autoload 'Compressor', 'pipefitter/compressor'

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

  def checksum
    @checksum ||= Checksum.new(base_path).checksum
  end

  private

  def compile_and_record_checksum
    if compiler.compile
      File.open(checksum_file, 'w+') do |file|
        file.write(checksum)
      end
    else
      raise CompilationError
    end
  end

  def archive
    if archiving_enabled?
      compressor.compress("#{checksum}.tar.gz")
    end
  end

  def compiler
    @compiler ||= Compiler.new(base_path)
  end

  def compressor
    @compressor ||= Compressor.new(base_path)
  end

  def assets_need_compiling?
    previous_checksum != checksum
  end

  def archiving_enabled?
    @archive
  end

  def checksum_directory
    File.join(base_path, 'tmp', 'pipefitter')
  end

  def checksum_file
    File.join(checksum_directory, 'checksum.txt')
  end

  def previous_checksum
    if File.exists?(checksum_file)
      File.read(checksum_file)
    else
      nil
    end
  end

  def setup
    FileUtils.mkdir_p(checksum_directory)
  end

  class Error < RuntimeError; end
  class CompilationError < Error; end
end

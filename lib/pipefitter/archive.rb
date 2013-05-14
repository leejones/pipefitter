require 'logger'
require 'fileutils'

class Pipefitter
  class Archive
    attr_reader :path, :limit

    def initialize(path, options = {})
      @path = path
      @logger = options.fetch(:logger, default_logger)
      @limit = options.fetch(:limit, 3)
      setup
    end

    def get(key)
      if artifact = artifacts.find { |f| f =~ /.*#{key}.*/ }
        if checksum_path = checksums.find { |f| f =~ /.*\.md5/ }
          checksum = File.read(checksum_path)
        else
          checksum = nil
        end
        Artifact.new(artifact, checksum)
      else
        nil
      end
    end

    def put(artifact_path, key)
      prefix = Time.now.to_i
      full_key = [prefix, key].join('-')
      full_key_path = File.join(path, full_key)
      Pipefitter::Artifact.create(artifact_path, full_key_path)
    end

    def purge
      if artifacts.count > limit
        artifacts.last(artifacts.count - limit).each do |artifact|
          key = File.basename(artifact, '.tar.gz')
          Dir.glob(File.join(path, "#{key}*")).each { |f| File.delete(f) }
        end
      end
    end

    class Error < RuntimeError; end
    class KeyNotFound < RuntimeError; end

    private

    def setup
      FileUtils.mkdir_p(path)
    end

    def artifacts
      files.select { |f| f =~ /.*\.tar\.gz/ }
    end

    def checksums
      files.select { |f| f =~ /.*\.md5/ }
    end

    def files
      Dir.glob(File.join(path, '*'))
    end

    def default_logger
      Logger.new(STDOUT)
    end
  end
end

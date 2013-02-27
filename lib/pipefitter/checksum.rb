require 'pipefitter/error'

class Pipefitter
  class Checksum
    attr_reader :paths

    def initialize(paths)
      @paths = paths
    end

    def self.checksum(paths)
      new(paths).checksum
    end

    def checksum
      verify_paths
      `find #{paths.join(' ')} -type f -exec md5 -q {} + | md5 -q`.strip
    end

    private

    def verify_paths
      paths.each do |path|
        unless File.exists?(path)
          raise PathNotFound, "Could not find #{path}"
        end
      end
    end

    class PathNotFound < Pipefitter::Error; end
  end
end

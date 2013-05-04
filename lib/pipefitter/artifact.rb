require 'pipefitter/error'
require 'pipefitter/checksum'

class Pipefitter
  class Artifact
    attr_reader :path, :checksum

    def self.create(source, target)
      checksum = Checksum.checksum(source)
      File.open("#{target}.md5", 'w+') { |f| f.write(checksum) }
      system "tar -C #{File.dirname(source)} -czf #{target} #{File.basename(source)}"
      new(target, checksum)
    end

    def initialize(path, checksum)
      @path = path
      @checksum = checksum
    end

    def expand_to(target)
      system "tar -C #{target} -xzf #{path}"
    end

    def verify_expansion(path)
      Checksum.checksum(path) == checksum
    end
  end
end

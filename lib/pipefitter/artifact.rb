require 'pipefitter/error'
require 'pipefitter/checksum'

class Pipefitter
  class Artifact
    attr_reader :path

    def self.create(source, target_path_prefix)
      checksum = Checksum.checksum(source)
      File.open("#{target_path_prefix}.md5", 'w+') { |f| f.write(checksum) }
      system "tar -C #{File.dirname(source)} -czf #{target_path_prefix}.tar.gz #{File.basename(source)}"
      new("#{target_path_prefix}.tar.gz", checksum)
    end

    def initialize(path, checksum = nil)
      @path = path
      @checksum = checksum
    end

    def checksum
      @checksum ||= begin
        if File.exists?(checksum_path)
          File.read(checksum_path)
        else
          nil
        end
      end
    end

    def checksum_path
      path.gsub('.tar.gz', '.md5')
    end

    def expand_to(target)
      system "tar -C #{target} -xzf #{path}"
    end

    def verify_expansion(path)
      Checksum.checksum(path) == checksum
    end
  end
end

class Pipefitter
  class Artifact
    attr_reader :path, :checksum

    def initialize(path, checksum)
      @path = path
      @checksum = checksum
    end

    def expand_to(target_path)
      expander = Artifact::Expander.new(self)
      expander.expand_to(target_path)
    end

    class Expander
      attr_reader :artifact

      def initialize(artifact)
        @artifact = artifact
      end

      def expand_to(target)
        system "tar -C #{target} -xzf #{artifact.path}"
      end
    end

    class Compressor
      attr_reader :source
      
      def initialize(source)
        @source = source
      end

      def compress_to(target)
        system "tar -C #{File.dirname(source)} -czf #{target} #{File.basename(source)}"
      end
    end
  end
end

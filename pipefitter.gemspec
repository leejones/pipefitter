# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pipefitter/version'

Gem::Specification.new do |gem|
  gem.name          = "pipefitter"
  gem.version       = Pipefitter::VERSION
  gem.authors       = ["Lee Jones"]
  gem.email         = ["scribblethink@gmail.com"]
  gem.description   = %q{A command-line tool that avoids unnecessary compiles when using the Rails Asset Pipeline.}
  gem.summary       = %q{Pipefitter answers the age old question of "To compile or not to compile?"}
  gem.homepage      = "https://github.com/leejones/pipefitter"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end

# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mamemose/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["daimatz"]
  gem.email         = ["dai@daimatz.net"]
  gem.description   = %q{Markdown memo server}
  gem.summary       = %q{Markdown memo server}
  gem.homepage      = "https://github.com/daimatz/mamemose"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mamemose"
  gem.require_paths = ["lib"]
  gem.version       = Mamemose::VERSION

  gem.add_dependency "redcarpet", "~> 2.3"
  gem.add_dependency "htmlentities", ">= 4.3.0"
  gem.add_dependency "thor", ">= 0.17.0"
  gem.add_dependency "em-websocket", ">= 0.5.0"
  gem.add_dependency "coderay", ">= 1.1.0"
end

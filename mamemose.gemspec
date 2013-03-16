# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mamemose/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["daimatz"]
  gem.email         = ["dai@daimatz.net"]
  gem.description   = %q{Markdown memo server}
  gem.summary       = %q{Markdown memo server}
  gem.homepage      = "https://github.com/daimatz/mamemose"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mamemose"
  gem.require_paths = ["lib"]
  gem.version       = Mamemose::VERSION

  gem.add_dependency "redcarpet", ">= 2.2.0"
  gem.add_dependency "htmlentities", ">= 4.3.0"
  gem.add_dependency "thor"
end

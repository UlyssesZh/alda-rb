# frozen_string_literal: true

require_relative 'lib/alda-rb/version'

Gem::Specification.new do |spec|
	spec.name          = "alda-rb"
	spec.version       = Alda::VERSION
	spec.authors       = ["Ulysses Zhan"]
	spec.email         = ["UlyssesZhan@gmail.com"]
	
	spec.summary       = %q{A Ruby library for live-coding music with Alda.}
	# spec.description   = %q{TODO: Write a longer description or delete this line.}
	spec.homepage      = "https://ulysseszh.github.io/doc/alda-rb"
	spec.license       = "MIT"
	spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")
	
	# spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
	
	spec.metadata["homepage_uri"] = spec.homepage
	spec.metadata["source_code_uri"] = "https://github.com/UlyssesZh/alda-rb"
	spec.metadata["changelog_uri"] = "https://ulysseszh.github.io/doc/alda-rb/CHANGELOG_md.html"
	
	# Specify which files should be added to the gem when it is released.
	# The `git ls-files -z` loads the files in the RubyGem that have been added into git.
	spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
		`git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	end
	spec.bindir        = "exe"
	spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]
	
	spec.add_runtime_dependency 'bencode'
	spec.add_runtime_dependency 'colorize'
	spec.add_development_dependency 'minitest', '~> 5.0'
	spec.add_development_dependency 'rake', '~> 13.0'
	spec.add_development_dependency 'rdoc'
end

# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-shortener/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-shortener"
  spec.version       = Jekyll::Shortener::VERSION
  spec.authors       = ["Brett Kosinski"]
  spec.email         = ["brettk@b-ark.ca"]
  spec.summary       = "A Jekyll plugin to generate short URLs for pages."
  spec.homepage      = "https://github.com/fancypantalons/jekyll-shortener"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r!^spec/!)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_runtime_dependency "jekyll", ">= 3.7", "< 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rubocop-jekyll", "~> 0.5"
end

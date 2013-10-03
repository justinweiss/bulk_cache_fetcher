# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bulk_cache_fetcher'

Gem::Specification.new do |spec|
  spec.name          = "bulk_cache_fetcher"
  spec.version       = BulkCacheFetcher::VERSION
  spec.authors       = ["Justin Weiss"]
  spec.email         = ["jweiss@avvo.com"]
  spec.description   = %q{Fetches cache misses in bulk}
  spec.summary       = %q{Bulk Cache Fetcher allows you to query the cache for a list of
objects, and gives you the opportunity to fetch all of the cache
misses at once, using whatever `:include`s you want.}
  spec.homepage      = "https://github.com/justinweiss/bulk_cache_fetcher"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end

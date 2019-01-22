# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activerecord/insert_many/version"

Gem::Specification.new do |spec|
  spec.name          = "activerecord-insert_many"
  spec.version       = Activerecord::InsertMany::VERSION
  spec.authors       = ["Luke Booth", "Bob Lail"]
  spec.email         = ["luke.booth@cph.org", "bob.lail@cph.org"]

  spec.summary       = %q{Adds a method for bulk-inserted records using ActiveRecord}
  spec.homepage      = "https://github.com/concordia-publishing-house/activerecord-insert_many"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-reporters-turn_reporter"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "shoulda-context"
  spec.add_development_dependency "pry"
end

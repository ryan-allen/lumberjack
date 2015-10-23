# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "lumberjack-dsl"
  s.version     = "0.0.3"
  s.license     = "MIT"
  s.authors     = ["Ryan Allen", "Steve Hodgkiss", "John Barton", "James Dowling"]
  s.email       = ["ryan@yeahnah.org", "steve@hodgkiss.me", "jrbarton@gmail.com", "jamesd741@gmail.com"]
  s.homepage    = "https://github.com/ryan-allen/lumberjack"
  s.summary     = %q{Lumberjack is best summed up as a generic DSL for constructing object trees.}
  s.description = <<-EOS.gsub(/^    /, "")
    Lumberjack is best summed up as a generic DSL for constructing object trees.

    It works great for configuration files, for generating a tree of configuration objects for later reflection or what-not. But in reality you could use it for whatever you're willing to dream up.
  EOS

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version     = '>= 1.9.3'

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest"
end

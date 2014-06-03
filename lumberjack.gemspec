# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "lumberjack-dsl"
  s.version     = "0.0.2"
  s.authors     = ["Ryan Allen", "Steve Hodgkiss", "John Barton", "James Dowling"]
  s.email       = ["ryan@yeahnah.org", "steve@hodgkiss.me", "jrbarton@gmail.com", "jamesd741@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Lumberjack is best summed up as a generic DSL for constructing object trees.}
  s.description = %q{}

  s.rubyforge_project = "lumberjack-dsl"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["."]
  s.required_ruby_version     = '>= 1.9.3'
end

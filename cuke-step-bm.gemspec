# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "cuke-step-bm"
  s.version     = "1.0.0"
  s.authors     = ["elvuel"]
  s.email       = ["elvuel@gmail.com"]
  s.homepage    = "https://github.com/elvuel"
  s.summary     = %q{cucumber steps benchmark}
  s.description = %q{cucumber steps benchmark}

  s.rubyforge_project = "cuke-step-bm"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end

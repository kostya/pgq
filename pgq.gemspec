# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/pgq/version"

Gem::Specification.new do |s|
  s.name = %q{pgq}
  s.version = Pgq::VERSION

  s.authors = ["Makarchev Konstantin"]
  s.autorequire = %q{init}
  
  s.description = %q{Queues system for AR/Rails based on PgQ Skytools for PostgreSQL, like Resque on Redis. Rails 3! only tested.}
  s.summary = %q{Queues system for AR/Rails based on PgQ Skytools for PostgreSQL, like Resque on Redis. Rails 3! only tested.}
  
  s.email = %q{kostya27@gmail.com}
  s.homepage = %q{http://github.com/kostya/pgq}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport', ">= 2.3.2"
  s.add_dependency 'activerecord', ">= 2.3.2"
  s.add_dependency 'pg'
  s.add_dependency 'marshal64'
  
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
end
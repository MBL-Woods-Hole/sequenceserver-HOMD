# -*- encoding: utf-8 -*-
# stub: slop 3.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "slop".freeze
  s.version = "3.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lee Jarvis".freeze]
  s.date = "2014-07-18"
  s.description = "A simple DSL for gathering options and parsing the command line".freeze
  s.email = "ljjarvis@gmail.com".freeze
  s.homepage = "http://github.com/leejarvis/slop".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.2.33".freeze
  s.summary = "Simple Lightweight Option Parsing".freeze

  s.installed_by_version = "3.2.33" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0.0"])
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0.0"])
  end
end

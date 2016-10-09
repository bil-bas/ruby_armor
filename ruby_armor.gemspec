# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'ruby_armor'
  s.version = '0.0.6alpha'

  s.required_rubygems_version = Gem::Requirement.new('> 1.3.1') if s.respond_to? :required_rubygems_version=
  s.authors = ['Bil Bas (Spooner)']
  s.date = '2012-02-27'
  s.email = ['bil.bagpuss@gmail.com']
  s.executables = ['ruby_armor']
  s.files         = `git ls-files`.split("\n")
  s.license       = 'MIT'

  s.homepage = 'http://spooner.github.com/libraries/ruby_armor/'
  s.licenses = ['MIT']
  s.require_paths = ['lib']
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.2')
  s.rubyforge_project = 'ruby_armor'
  s.rubygems_version = '1.8.16'
  s.summary = 'GUI interface for RubyWarrior'

  s.add_runtime_dependency('rubywarrior', ['~> 0.1', '>= 0.1.2'])
  s.add_runtime_dependency('gosu', ['~> 0.10', '>= 0.7.41'])
  s.add_runtime_dependency('chingu', ['~> 0.9rc9'])
  s.add_runtime_dependency('fidgit', ['~> 0.2', '>= 0.2.7'])
  s.add_development_dependency('releasy', ['~> 0.2', '>= 0.2.2'])
end

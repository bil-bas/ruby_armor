# -*- encoding: utf-8 -*-

task :gemspec do
  generate_gemspec
end

file "gale.gemspec" do
  generate_gemspec
end

def generate_gemspec
  puts "Generating gemspec"

  require_relative "../lib/ruby_armor/version"

  spec = Gem::Specification.new do |s|
    s.name = "ruby_armor"
    s.version = RubyArmor::VERSION

    s.platform    = Gem::Platform::RUBY
    s.authors     = ["Bil Bas (Spooner)"]
    s.email       = ["bil.bagpuss@gmail.com"]
    s.homepage    = "http://spooner.github.com/libraries/ruby_armor/"
    s.summary     = %q{GUI interface for RubyWarrior}

    # TODO: Add the DLL when permission is granted.
    s.files = DISTRO_FILES
    s.licenses = ["MIT"]
    s.rubyforge_project = s.name

    s.executable = s.name

    s.test_files = Dir["test/**/*_spec.rb"]

    s.add_runtime_dependency "rubywarrior", "~> 0.1.2"
    s.add_runtime_dependency "gosu", "~> 0.7.41"
    s.add_runtime_dependency "chingu", "~> 0.9rc7"
    s.add_runtime_dependency "fidgit", "~> 0.2.1"

    s.add_development_dependency "releasy", "~> 0.2.2"
  end

  File.open("#{spec.name}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end
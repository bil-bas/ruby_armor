# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ruby_armor"
  s.version = "0.0.5alpha"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bil Bas (Spooner)"]
  s.date = "2012-02-27"
  s.email = ["bil.bagpuss@gmail.com"]
  s.executables = ["ruby_armor"]
  s.files = ["config/default_config.yml", "config/gui", "config/gui/schema.yml", "lib/ruby_armor", "lib/ruby_armor/base_user_data.rb", "lib/ruby_armor/floating_text.rb", "lib/ruby_armor/ruby_warrior_ext", "lib/ruby_armor/ruby_warrior_ext/abilities", "lib/ruby_armor/ruby_warrior_ext/abilities/rest.rb", "lib/ruby_armor/ruby_warrior_ext/position.rb", "lib/ruby_armor/ruby_warrior_ext/ui.rb", "lib/ruby_armor/ruby_warrior_ext/units", "lib/ruby_armor/ruby_warrior_ext/units/base.rb", "lib/ruby_armor/sprite_sheet.rb", "lib/ruby_armor/states", "lib/ruby_armor/states/choose_profile.rb", "lib/ruby_armor/states/play.rb", "lib/ruby_armor/states/review_code.rb", "lib/ruby_armor/version.rb", "lib/ruby_armor/warrior_config.rb", "lib/ruby_armor/window.rb", "lib/ruby_armor.rb", "media/fonts", "media/fonts/Licence.txt", "media/fonts/ProggyCleanSZ.ttf", "media/images", "media/images/mobs.png", "media/images/tiles.png", "media/images/warriors.png", "README.md", "bin/ruby_armor"]
  s.homepage = "http://spooner.github.com/libraries/ruby_armor/"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("~> 1.9.2")
  s.rubyforge_project = "ruby_armor"
  s.rubygems_version = "1.8.16"
  s.summary = "GUI interface for RubyWarrior"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubywarrior>, ["~> 0.1.2"])
      s.add_runtime_dependency(%q<gosu>, ["~> 0.7.41"])
      s.add_runtime_dependency(%q<chingu>, ["~> 0.9rc7"])
      s.add_runtime_dependency(%q<fidgit>, ["~> 0.2.4"])
      s.add_development_dependency(%q<releasy>, ["~> 0.2.2"])
    else
      s.add_dependency(%q<rubywarrior>, ["~> 0.1.2"])
      s.add_dependency(%q<gosu>, ["~> 0.7.41"])
      s.add_dependency(%q<chingu>, ["~> 0.9rc7"])
      s.add_dependency(%q<fidgit>, ["~> 0.2.4"])
      s.add_dependency(%q<releasy>, ["~> 0.2.2"])
    end
  else
    s.add_dependency(%q<rubywarrior>, ["~> 0.1.2"])
    s.add_dependency(%q<gosu>, ["~> 0.7.41"])
    s.add_dependency(%q<chingu>, ["~> 0.9rc7"])
    s.add_dependency(%q<fidgit>, ["~> 0.2.4"])
    s.add_dependency(%q<releasy>, ["~> 0.2.2"])
  end
end

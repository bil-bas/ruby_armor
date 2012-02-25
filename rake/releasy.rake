require 'releasy'

require_relative "../lib/ruby_armor/version"

Releasy::Project.new do
  name "Ruby Armor"
  version RubyArmor::VERSION

  files DISTRO_FILES

  exposed_files %w[README.md]
  add_link "http://spooner.github.com/games/ruby_armor", "RubyArmor website"
  exclude_encoding

  add_build :osx_app do
    wrapper "../releasy/wrappers/gosu-mac-wrapper-0.7.41.tar.gz"
    url "com.github.spooner.games.ruby_armor"
    #icon "media/icon.icns"
    add_package :tar_gz
  end

  add_build :source do
    add_package :zip
  end

  add_build :windows_folder do
    #icon "media/icon.ico"
    add_package :exe
    executable_type :windows
  end

  add_build :windows_installer do
    #icon "media/icon.ico"
    start_menu_group "Spooner Games"
    readme "README.html"
    add_package :zip
    executable_type :windows
  end

  add_deploy :local do
    path "C:/users/spooner/dropbox/Public/games/ruby_armor"
  end
end
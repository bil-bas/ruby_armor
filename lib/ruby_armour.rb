require "ruby_warrior"

require "gosu"
require "chingu"
require "fidgit"

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "ruby_armour/ruby_warrior_ext/position"
require "ruby_armour/ruby_warrior_ext/ui"
require "ruby_armour/states/play"
require "ruby_armour/window"

RubyArmour::Window.new.show


require "ruby_warrior"

require "gosu"
require "chingu"
require "fidgit"

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "ruby_armor/ruby_warrior_ext/position"
require "ruby_armor/ruby_warrior_ext/ui"
require "ruby_armor/states/play"
require "ruby_armor/window"

RubyArmor::Window.new.show


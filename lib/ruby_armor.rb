require "ruby_warrior"

require 'yaml'

require "gosu"
require "chingu"
require "fidgit"

include Gosu
include Chingu

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "ruby_armor/version"

require "ruby_armor/ruby_warrior_ext/position"
require "ruby_armor/ruby_warrior_ext/ui"
require "ruby_armor/ruby_warrior_ext/player_generator"
require "ruby_armor/ruby_warrior_ext/units/base"
require "ruby_armor/ruby_warrior_ext/abilities/rest"

require "ruby_armor/floating_text"
require "ruby_armor/sprite_sheet"
require "ruby_armor/states/create_profile"
require "ruby_armor/states/choose_profile"
require "ruby_armor/states/play"
require "ruby_armor/states/review_code"
require "ruby_armor/dungeon_view"
require "ruby_armor/window"
require "ruby_armor/warrior_config"

ROOT_PATH = File.expand_path('../../', __FILE__)

# Setup Chingu's autoloading media directories.
media_dir = File.expand_path('media', ROOT_PATH)
Image.autoload_dirs.unshift File.join(media_dir, 'images')
Sample.autoload_dirs.unshift File.join(media_dir, 'sounds')
Song.autoload_dirs.unshift File.join(media_dir, 'music')
Font.autoload_dirs.unshift File.join(media_dir, 'fonts')

Fidgit::Element.schema.merge_schema! YAML.load(File.read(File.expand_path('config/gui/schema.yml', ROOT_PATH)))


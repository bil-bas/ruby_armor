module RubyArmor
  class SpriteSheet
    extend Forwardable

    def_delegators :@sprites, :map, :each

    class << self
      def [](file, width, height, tiles_wide = 0)
        @cached_sheets ||= Hash.new do |h, k|
           h[k] = new(*k)
        end
        @cached_sheets[[file, width, height, tiles_wide]]
      end
    end

    def initialize(file, width, height, tiles_wide = 0)
      @sprites = Image.load_tiles($window, File.expand_path(file, Image.autoload_dirs[0]), width, height, false)
      @tiles_wide = tiles_wide
    end

    def [](x, y = 0)
      @sprites[y * @tiles_wide + x]
    end
  end
end
module RubyWarrior
  class PlayerGenerator
    def generate
      if level.number == 1
        FileUtils.mkdir_p(level.player_path)
        # Read and write, so that line-endings are correct for the OS.
        File.open(level.player_path + '/player.rb', "w") do |f|
          f.write File.read(templates_path + '/player.rb')
        end
      end

      File.open(level.player_path + '/README', 'w') do |f|
        f.write read_template(templates_path + '/README.erb')
      end
    end
  end
end
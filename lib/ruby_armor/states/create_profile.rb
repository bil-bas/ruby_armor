module RubyArmor
  class CreateProfile < Fidgit::DialogState
    DEFAULT_WARRIOR_CLASS = :valkyrie

    def initialize(game, warrior_sprites)
      @game = game

      super shadow_full: true

      on_input :escape, :hide
      on_input [:return, :enter] do
        @new_profile_button.activate if @new_profile_button.enabled?
      end

      # Option to create a new profile.
      vertical align: :center, border_thickness: 4, background_color: Color::BLACK do
        label "Create new profile", font_height: 20

        @new_name = text_area width: 300, height: 30, font_height: 20 do |_, text|
          duplicate = @game.profiles.any? {|p| p.warrior_name.downcase == text.downcase }
          @new_profile_button.enabled = !(text.empty? or duplicate)
        end

        # Choose class; just cosmetic.
        @warrior_class = group align_h: :center do
          horizontal padding: 0, align_h: :center do
            DungeonView::WARRIORS.each do |warrior, row|
              radio_button "", warrior, tip: "Play as a #{warrior.capitalize} (The difference between classes is purely cosmetic!)",
                           :icon => warrior_sprites[0, row], :icon_options => { :factor => 4 }
            end
          end
        end

        horizontal align: :center do
          button "Cancel" do
            hide
          end

          @new_profile_button = button "Create", justify: :center, tip: "Create a new profile" do
            play *new_profile(@new_name.text)
          end
        end

        new_name = File.basename File.expand_path("~")
        new_name = "Player" if new_name.empty?
        @new_name.text = new_name

        @warrior_class.value = DEFAULT_WARRIOR_CLASS
      end
    end

    def update
      super
      @new_name.focus self unless @new_name.focused?
    end

    def finalize
      super
      container.clear
    end

    def play(profile, config)
      @game.instance_variable_set :@profile, profile
      hide
      push_game_state Play.new(@game, config)
    end

    def new_profile(name)
      new_profile = RubyWarrior::Profile.new
      new_profile.tower_path = @game.towers[0].path
      new_profile.warrior_name = name

      config = WarriorConfig.new new_profile
      config.warrior_class = @warrior_class.value

      [new_profile, config]
    end
  end
end
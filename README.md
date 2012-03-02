Ruby Armor
==========

A graphical front-end for [RubyWarrior](https://github.com/ryanb/ruby-warrior). Make sure your Ruby Warrior is wearing Ruby Armor!

* Author: Spooner / Bil Bas (bil.bagpuss@gmail.com)
* License: [MIT](http://opensource.org/licenses/MIT)
* Website: http://spooner.github.com/games/ruby_armor/
* Project: https://github.com/Spooner/ruby_armor

Features
--------

RubyArmor has all the features of [RubyWarrior](https://github.com/ryanb/ruby-warrior), but with a more friendly, graphical interface. It also adds some unique features:

### Extended functionality

* After a level has been finished (completed or failed) the user can drag a slider to see what the state was during each turn.
* Records code and score when each level is completed. This code can be reviewed at any point later, which can be used to see how your code evolved during play.
* Speed of playback can be changed while watching the game being played (from one turn per display frame, up to one turn per second). Preferred playback speed is saved with the profile.
* At any point, user can reset the level back to the start, without having to wait to see it played out to the end.
* The text log can be viewed as individual turns rather than the normal stream of turns. This can make it easier to follow.

### Purely cosmetic additions

* The rogue-like ASCII game display is also displayed with colourful graphics in a pixelated style.
* Floating numbers appear when damage is taken or healed.
* Can choose whether you play as a Valkyrie, Mercenary, Monk or Burglar (This difference is entirely cosmetic, since it just changes the graphics used for the warrior).

Installation
------------

RubyArmor requires Ruby 1.9.2 or higher (sorry!). It is still in an alpha state, so must be installed using `--pre`

    > gem install ruby_armor --pre

Play
----

    > ruby_armor

Credits
-------

* A myriad thanks to ryanb for making such an inspiring game as RubyWarrior!
* Thanks to jlnr and RomyRomy for play-testing and suggestions.


Third party assets used
-----------------------

* Font: [ProggyCleanSZ.ttf](http://proggyfonts.com)
* Sprites made by Oryx from his [LOFI Sprite Pack](http://cgbarrett.squarespace.com/sprites/). [![CC BY-NC-ND](http://i.creativecommons.org/l/by-nc-nd/3.0/88x31.png)](http://creativecommons.org/licenses/by-nc-nd/3.0/)
* [Gosu](http://libgosu.org/) game development library
* [Chingu](http://ippa.se/chingu) game library (extending Gosu)
* [Fidgit](https://github.com/Spooner/fidgit) gui library (extending Chingu)
* [RubyWarrior](https://github.com/ryanb/ruby-warrior) gem

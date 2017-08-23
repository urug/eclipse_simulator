# eclipse_simulator

Visualizers to show sun and moon positions, give a certain time and position on
the earth. Two examples are present, using Gosu and Ruby2D.

To install the gosu and ruby2d gem you will also need the following libraries:
* gosu (brew install gosu on macos)
* sdl2 (brew install sdl2 on macos)
* simple2d (`brew tap simple2d/tap; brew install simple2d` on macos)

After installing the gems, do `bundle install` an normal.

The green line is the horizon and will move up and down depending on the time
of the year.

Default starting position on the earth is Grand Teton National Park, which
will be in the path of totality for the 2017 Eclipse. Default time is the
projected time of totality for that location.

You can move through time with the left and right arrows. By default, right
arrow will move you 1 hour ahead, left will move you one hour behind. You can
change the movement speed using the up and down arrows. Your current movement
speed is shown in the window title bar.

The "r" key will set the time to be sunrise of the current day.

The "s" key will set the time to be sunset of the current day.
Escape will exit.

You can change the position on earth by changing the value of `@coords`:
Insert your preferred Lat/Long coordinates in decimal format.

You can also change the default start time by changing `@current_time`. You can
also uses the SunCalc gem to set the time to be sunrise, sunset, mid-day, etc.

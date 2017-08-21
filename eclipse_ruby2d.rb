#!/usr/bin/env ruby
#
# Visualizer to show sun and moon positions, give a certain time and position on
# the earth.
#
# Uses "gosu" so you will need to install the following libraries:
#  * simple2d (`brew tap simple2d/tap; brew install simple2d` on macos)
#
# Uses gems:
#  * suncalc
#  * ruby2d

# The moon is the grey body, the sun is the red body.
#
# The green line is the horizon and will move up and down depending on the time
# of the year.
#
# Default starting position on the earth is Grand Teton National Park, which
# will be in the path of totality for the 2017 Eclipse. Default time is the
# projected time of totality for that location.
#
# You can move through time with the left and right arrows. By default, right
# arrow will move you 1 hour ahead, left will move you one hour behind. You can
# change the movement speed using the up and down arrows. Your current movement
# speed is shown in the window title bar.
#
# The "r" key will set the time to be sunrise of the current day.
#
# The "s" key will set the time to be sunset of the current day.
#
# Escape will exit.
#
# You can change the position on earth by changing the value of `@coords`
# defined inthe Eclipse#initialize method. Insert your prefered Lat/Long
# coordinates in decimal format.
#
# You can also change the default start time by changing `@current_time`
# defined in the Eclipse#initialize method. You can also uses the SunCalc gem
# to set the time to be sunrise, sunset, mid-day, etc.


require 'suncalc'
require 'time'

require 'ruby2d'
# `brew tap simple2d/tap; brew install simple2d`

MOVEMENTS_MODES = [
  # name, times, change in seconds * times
  ['1 Minute', 1, 60],
  ['1 Hour', 60, 60],
  ['1 Day', 24, 3600],
  ['30 Days', 30, 86400],
  ['365 Days', 365, 86400],
  ['5 years', 5, 86400*365.25]
]

def get_times
  SunCalc.get_times(@current_time, @coords.first, @coords.last)
end

# Sets horizon Y coordiate to be same as suns Y position at sunrise
def update_horizon_y
  sunrise_time = get_times[:sunrise]

  sunrise_coords = SunCalc.get_position(sunrise_time, @coords.first, @coords.last)

  @horizon_y =  map_range([-180, +180], [@height-@sun_d/2, @sun_d], sph2cart(sunrise_coords[:azimuth], sunrise_coords[:altitude])[:y]).to_i
end

def update_coords
  @sun_coords =  SunCalc.get_position(@current_time, @coords.first, @coords.last)
  @moon_coords = SunCalc.get_moon_position(@current_time, @coords.first, @coords.last)
end

def update_data
  # puts "#update_data"
   if @counter != 0
    update_horizon_y
    update_caption
  end

  if @counter < 0
    @current_time -= MOVEMENTS_MODES[@current_movement_mode][2]
    @counter += 1
  elsif @counter > 0
    @current_time += MOVEMENTS_MODES[@current_movement_mode][2]
    @counter -= 1
  elsif @counter == 0 && @moving
    update_horizon_y
    @moving = false
  end

  update_coords
end

def draw
  # puts "#draw"
  # Set Y axis position of horizon
  @horizon.y = @horizon_y

  # Set Y axis position of "you"
  @you.y = @horizon_y-@you_d

  # Set X/Y axis positions of Sun - Red sphere
  @sun.x = map_range([-180, +180], [@width-@sun_d/2, @sun_d], sph2cart(@sun_coords[:azimuth], @sun_coords[:altitude])[:x]).to_i-(@sun_d/2)
  @sun.y = map_range([-180, +180], [@height-@sun_d/2, @sun_d], sph2cart(@sun_coords[:azimuth], @sun_coords[:altitude])[:y]).to_i-(@sun_d/2)

  # Set X/Y axis positions of Moon - Grey sphere
  @moon.x = map_range([-180, +180], [@width-@moon_d/2, @moon_d], sph2cart(@moon_coords[:azimuth], @moon_coords[:altitude])[:x]).to_i-(@moon_d/2)
  @moon.y = map_range([-180, +180], [@height-@moon_d/2, @moon_d], sph2cart(@moon_coords[:azimuth], @moon_coords[:altitude])[:y]).to_i-(@moon_d/2)

  unless @moving
    # To prevent needless rapid redrawing if the screen isn't changing
    sleep(0.25)
    update_caption
  end
end

def update_caption
  # puts "#update_caption"
  @caption.text = "#{(@current_time)} - #{MOVEMENTS_MODES[@current_movement_mode][0]}"
end

# Maps a number from one numeric range to another. In this case we need to be
# able to map the coordinates of the sun/moon in to the coordinate range of
# the Gosu window.
def map_range(a, b, s)
  af, al, bf, bl = a.first, a.last, b.first, b.last
  bf + (s - af)*(bl - bf).quo(al - af)
end

# Convert Spherical coordinates (azimuth/elevation) in to cartesian (x/y) coordinates
# https://www.mathworks.com/help/matlab/ref/sph2cart.html?requestedDomain=www.mathworks.com#input_argument_d0e929631
def sph2cart(azimuth, elevation)
  {
    # x: 180 * Math.cos(elevation) * Math.cos(azimuth),
    # y: 180 * Math.cos(elevation) * Math.sin(azimuth)
    x: 180 * Math.cos(elevation) * Math.sin(azimuth),
    y: 180 * Math.cos(elevation) * Math.cos(azimuth)

  }
end


@width = 1024
@height = 746
set width: @width, height: @height, title: "Eclipse"

@caption = Text.new(x: 5, y: 5, text: "Eclipse", size: 30, font: '/Users/mnielsen/Downloads/Random_font.ttf')
# @caption.color = 'fuchsia'

@moon_d = 49
@moon = Image.new(width: @moon_d, height: @moon_d, path: './moon.png', z: 10)
@sun_d = 50
@sun = Image.new(width: @sun_d, height: @sun_d, path: './sun.png', z: 0)
@you_d = 10
@you = Rectangle.new(width: @sun_d/4, height: @sun_d/4, x: @width/2, y: 0, color: 'blue')

@horizon = Rectangle.new(x: 0, y: 0, width: @width, height: 1, z: 0, color: 'green')

# @coords = [40.768860, -111.893273] # Salt Lake City, Utah
@coords = [43.833333, -110.700833] # grand teton NP, 11:36am

@current_time = Time.parse('2017-08-21 10:36:00') # grand teton NP totality, in MST/MDT time
# @current_time = Time.parse('1978-04-07 06:28:00 -070') # Bonus: 1978 Eclipse, near-totality in grand teton NP
# @current_time = SunCalc.get_times(Time.now, @coords.first, @coords.last)[:solar_noon]
# @current_time = SunCalc.get_times(Time.now, @coords.first, @coords.last)[:sunrise]
# @current_time = SunCalc.get_times(Time.now, @coords.first, @coords.last)[:sunset]
# @current_time = SunCalc.get_times(Time.parse('June 21, 2018'), @coords.first, @coords.last)[:sunrise]

# Can use one of: [:solar_noon, :nadir, :sunrise, :sunset, :sunrise_end, :sunset_start, :dawn, :dusk, :nautical_dawn, :nautical_dusk, :night_end, :night, :golden_hour_end, :golden_hour]

@current_movement_mode = 1

update_coords
update_horizon_y

@counter = 0

update do
  # puts "update loop"
  update_data
  draw
end

on :key_down do |event|
  # puts event.inspect
  if !@moving
    case event[:key]
    when 'right'
      @moving = true
      puts "Forward in time #{MOVEMENTS_MODES[@current_movement_mode][0]}"
      @counter = MOVEMENTS_MODES[@current_movement_mode][1]
    when 'left'
      @moving = true
      puts "Backward in time #{MOVEMENTS_MODES[@current_movement_mode][0]}"
      @counter = -MOVEMENTS_MODES[@current_movement_mode][1]
    when 'up'
      @current_movement_mode += 1
      @current_movement_mode = 0 if @current_movement_mode > MOVEMENTS_MODES.length-1
    when 'down'
      @current_movement_mode -= 1
      @current_movement_mode = MOVEMENTS_MODES.length-1 if @current_movement_mode < 0
    when 'r'
      @current_time = get_times[:sunrise]
    when 's'
      @current_time = get_times[:sunset]
    when 'escape'
      # exit
      close
    end
  end
end

show # Draw the ruby2d window

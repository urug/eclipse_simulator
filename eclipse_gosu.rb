#!/usr/bin/env ruby
#
# Visualizer to show sun and moon positions, give a certain time and position on
# the earth.
#
# Uses "gosu" so you will need to install the following libraries:
#  * gosu (brew install gosu on macos)
#  * sdl2 (brew install sdl2 on macos)
#
# Uses gems:
#  * suncalc
#  * gosu

# The moon is the brighter of the two bodies. The sun is the dimmer of the two.
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

require 'gosu'
# brew install gosu
# brew install sdl2

# https://gist.github.com/jlnr/661266
class Circle
  attr_reader :columns, :rows

  def initialize radius, color = 255
    @columns = @rows = radius * 2
    lower_half = (0...radius).map do |y|
      x = Math.sqrt(radius**2 - y**2).round
      right_half = "#{color.chr * x}#{0.chr * (radius - x)}"
      "#{right_half.reverse}#{right_half}"
    end.join
    @blob = lower_half.reverse + lower_half
    @blob.gsub!(/./) { |alpha| "#{255.chr}#{255.chr}#{255.chr}#{alpha}"}
  end

  def to_blob
    @blob
  end
end

class Eclipse < Gosu::Window
  MOVEMENTS_MODES = [
    # name, times, change in seconds * times
    ['1 Minute', 1, 60],
    ['1 Hour', 60, 60],
    ['1 Day', 24, 3600],
    ['30 Days', 30, 86400],
    ['365 Days', 365, 86400],
    ['5 years', 5, 86400*365.25]
  ]

  def initialize
    @width = 1024
    @height = 746
    super @width, @height
    self.caption = "Eclipse"

    @moon_d = 24
    @moon = Gosu::Image.new(self, Circle.new(@moon_d, 255), false)
    @sun_d = 25
    @sun = Gosu::Image.new(self, Circle.new(@sun_d, 128), false)
    @you_d = 10
    @you = Gosu::Image.new(self, Circle.new(@you_d, 200), false)

    # @coords = [40.768860, -111.893273] # Salt Lake City, Utah
    @coords = [43.833333, -110.700833] # grand teton NP, 11:36am

    @current_time = Time.parse('2017-08-21 10:36:00') # grand teton NP totality, in MST/MDT time
    # @current_time = SunCalc.get_times(Time.now, @coords.first, @coords.last)[:solar_noon]
    # @current_time = SunCalc.get_times(Time.now, @coords.first, @coords.last)[:sunrise]
    # @current_time = SunCalc.get_times(Time.now, @coords.first, @coords.last)[:sunset]
    # @current_time = SunCalc.get_times(Time.parse('June 21, 2018'), @coords.first, @coords.last)[:sunrise]

    # Can use one of: [:solar_noon, :nadir, :sunrise, :sunset, :sunrise_end, :sunset_start, :dawn, :dusk, :nautical_dawn, :nautical_dusk, :night_end, :night, :golden_hour_end, :golden_hour]

    @current_movement_mode = 1

    update_coords
    update_horizon_y
    puts 'update_horizon_y'

    @counter = 0
  end

  def button_down(id)
    return if @moving
    case id
    when Gosu::Button::KbRight
      @moving = true
      puts "Forward in time #{MOVEMENTS_MODES[@current_movement_mode][0]}"
      @counter = MOVEMENTS_MODES[@current_movement_mode][1]
    when Gosu::Button::KbLeft
      @moving = true
      puts "Backward in time #{MOVEMENTS_MODES[@current_movement_mode][0]}"
      @counter = -MOVEMENTS_MODES[@current_movement_mode][1]
    when Gosu::Button::KbUp
      @current_movement_mode += 1
      @current_movement_mode = 0 if @current_movement_mode > MOVEMENTS_MODES.length-1
    when Gosu::Button::KbDown
      @current_movement_mode -= 1
      @current_movement_mode = MOVEMENTS_MODES.length-1 if @current_movement_mode < 0
    when Gosu::Button::KbR
      @current_time = get_times[:sunrise]
    when Gosu::Button::KbS
      @current_time = get_times[:sunset]
    when Gosu::Button::KbEscape
      exit
    end
  end

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

  def update
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
    # draw horizon
    draw_line(0, @horizon_y, Gosu::Color::GREEN, @width, @horizon_y, Gosu::Color::GREEN)

    # draw "you"
    @you.draw(@width/2, @horizon_y-@you_d, 0)

    # Draw sun sphere - the dimmer of the two
    @sun.draw(
      map_range([-180, +180], [@width-@sun_d/2, @sun_d], sph2cart(@sun_coords[:azimuth], @sun_coords[:altitude])[:x]).to_i-(@sun_d/2),
      map_range([-180, +180], [@height-@sun_d/2, @sun_d], sph2cart(@sun_coords[:azimuth], @sun_coords[:altitude])[:y]).to_i-(@sun_d/2),
      0
    )

    # Draw moon sphere - the brighter of the two
    @moon.draw(
      map_range([-180, +180], [@width-@moon_d/2, @moon_d], sph2cart(@moon_coords[:azimuth], @moon_coords[:altitude])[:x]).to_i-(@moon_d/2),
      map_range([-180, +180], [@height-@moon_d/2, @moon_d], sph2cart(@moon_coords[:azimuth], @moon_coords[:altitude])[:y]).to_i-(@moon_d/2),
      0
    )

    unless @moving
      # To prevent needless rapid redrawing if the screen isn't changing
      sleep(0.25)
      update_caption
    end
  end

  def update_caption
    self.caption = "#{(@current_time)} - #{MOVEMENTS_MODES[@current_movement_mode][0]}"
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

end

Eclipse.new.show

# frozen_string_literal: true

class Location
  attr_accessor :x, :y

  def initialize(pos_x, pos_y)
    @x = pos_x
    @y = pos_y
  end

  def inspect
    "(#{x},#{y})"
  end

  def delta(location)
    dx = (x - location.x).abs
    dy = (y - location.y).abs
    Math.sqrt(dx**2 + dy**2)
  end
end

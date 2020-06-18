# frozen_string_literal: true

Location = Struct.new(:x, :y) do
  def inspect
    "(#{x},#{y})"
  end

  def distance(location)
    dx = (x - location.x).abs
    dy = (y - location.y).abs
    Math.sqrt(dx**2 + dy**2)
  end
end

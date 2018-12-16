require 'set'

pos_and_vels = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

def yrange_at_time(pos_and_vels, t)
  ymin, ymax = pos_and_vels.map { |_, y, _, vy| y + vy * t }.minmax
  ymax - ymin
end

# Binary search for the time when yrange is at its lowest.
# Note that this isn't guaranteed to be the solution in general:
# * the points might collapse into one location
# * some points might not be involved in the message
# but for the class of inputs encountered in Advent of Code, it's good.
best_time = (0..yrange_at_time(pos_and_vels, 0)).bsearch { |t|
  yrange_at_time(pos_and_vels, t + 1) > yrange_at_time(pos_and_vels, t)
}

points = pos_and_vels.map { |x, y, vx, vy| [x + vx * best_time, y + vy * best_time] }
ymin, ymax = points.map(&:last).minmax
xmin, xmax = points.map(&:first).minmax
points = Set.new(points)

(ymin..ymax).each { |y|
  (xmin..xmax).each { |x|
    print points.include?([x, y]) ? ?# : ' '
  }
  puts
}
puts

puts best_time

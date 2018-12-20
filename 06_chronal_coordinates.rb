VERBOSE = ARGV.delete('-v')
DIST = if (darg = ARGV.find { |a| a.start_with?('-d') })
  ARGV.delete(darg)
  Integer(darg[2..-1])
else
  10000
end

points = ARGF.map { |l|
  l.split(', ').map(&method(:Integer)).freeze
}.freeze

ymin, ymax = points.map(&:first).minmax
xmin, xmax = points.map(&:last).minmax

owned = [0] * points.size
infinite = [false] * points.size

# Part 1
# Calculate closest labeled point for all points within the bounding box.
# Anything that keeps growing beyond the box we'll call "infinite"
#
# I thought we might need a margin to deal w/ cases like this:
# A     B
#    C
#    D
# However, in such a case, C is actually infinite (extends upwards),
# and no amount of distance away from C will fix that.
#
# So no margin is needed.
MARGIN = 0
yrange = (ymin - MARGIN)..(ymax + MARGIN)
xrange = (xmin - MARGIN)..(xmax + MARGIN)
yrange.each { |y|
  edge_y = y == yrange.begin || y == yrange.end
  # Since y distance depends only on y,
  # it saves some time to precalculate it.
  # Cuts runtime to about 0.9x.
  y_dists = points.map { |yy, _| (yy - y).abs }

  xrange.each { |x|
    best_dist = 1.0 / 0.0
    best = nil
    total_dist = 0

    # I'd use zip here, but it's demonstrably slower
    # (since it constructs additional arrays)
    points.each_with_index { |(_, xx), i|
      dist = y_dists[i] + (xx - x).abs
      if dist < best_dist
        best = i
        best_dist = dist
      elsif dist == best_dist
        best = nil
      end
      total_dist += dist
    }

    edge_x = x == xrange.begin || x == xrange.end

    next unless best

    if edge_y || edge_x
      infinite[best] = true
    else
      owned[best] += 1
    end
  }
}

p owned.zip(infinite) if VERBOSE
puts owned.zip(infinite).reject(&:last).map(&:first).max

within = 0

y_dists = yrange.to_h { |y| [y, points.sum { |yy, _| (yy - y).abs }] }.freeze
x_dists = xrange.to_h { |x| [x, points.sum { |_, xx| (xx - x).abs }] }.freeze

yrange.each { |y|
  edge_y = y == yrange.begin || y == yrange.end
  ydist = y_dists[y]

  xrange.each { |x|
    edge_x = x == xrange.begin || x == xrange.end
    total_dist = ydist + x_dists[x]

    if total_dist < DIST
      within += 1
      puts "DANGER! SAFE ON EDGE #{y}, #{x}" if edge_y || edge_x
    end
  }
}

puts within

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
height = ymax - ymin + 1
width = xmax - xmin + 1

# Part 1
# Simultaneous flood-fill out from all labeled points.

# Compress all points into a single integer,
# rather than creating two-element [y, x] arrays.
# Creating tons of arrays takes unreasonably long.
flat_points = points.map { |(y, x)| (y - ymin) * width + (x - xmin) }.freeze

owned = [1] * points.size
infinite = [false] * points.size

queues = flat_points.map { |p| [p] }

seen_dist = [nil] * (height * width)
claim = [nil] * (height * width)
flat_points.each_with_index { |p, i|
  claim[p] = i
  seen_dist[p] = 0
}

dist = 0

until queues.all?(&:empty?)
  dist += 1

  queues = queues.map.with_index { |q, i|
    q.flat_map { |p|
      nq = []
      # Note that any point on the bounding box causes its owner to be infinite,
      # since a step away from the bounding box increases all distances.
      # Unfortunately, we do need to unflatten here,
      # because we need to check individual coordinates.
      y, x = p.divmod(width)
      if y == 0;          infinite[i] = true else nq << p - width end
      if y == height - 1; infinite[i] = true else nq << p + width end
      if x == 0;          infinite[i] = true else nq << p - 1 end
      if x == width - 1;  infinite[i] = true else nq << p + 1 end
      # Exclude points that have been claimed in an earlier iteration.
      # (Could do this check above, but code would be repeated 4x)
      nq.reject! { |pp| seen_dist[pp] &.< dist }
      nq
    }.uniq.each { |p|
      # Either claim an unclaimed point or clash with a claimant.
      claim[p] = claim[p] ? :clash : i
    }
  }

  queues.each_with_index { |nq, i|
    nq.reject! { |p|
      if claim[p] == i
        # Only claimant this round - claim is confirmed.
        owned[i] += 1
        seen_dist[p] = dist
      end
      # Remove points where we clashed,
      # since neither claimant will make progress.
      claim[p] == :clash
    }
  }
end

p owned.zip(infinite) if VERBOSE
puts owned.zip(infinite).reject(&:last).map(&:first).max

# Margin may be needed if points are too close together.
MARGIN = 0
yrange = (ymin - MARGIN)..(ymax + MARGIN)
xrange = (xmin - MARGIN)..(xmax + MARGIN)

y_dists = yrange.to_h { |y| [y, points.sum { |yy, _| (yy - y).abs }] }.freeze
x_dists = xrange.to_h { |x| [x, points.sum { |_, xx| (xx - x).abs }] }.freeze

# Both distance arrays have a falling half and a rising half.
# We'll break the X range into these two halves.
rising_xrange = nil
falling_xrange = nil
x_dists.each_cons(2) { |(x1, sum1), (_, sum2)|
  if falling_xrange
    break rising_xrange = x1..xrange.end if sum2 > sum1
  elsif sum2 >= sum1
    falling_xrange = xrange.begin..x1
  end
}

# Because of how bsearch works, it's better to search rising in reverse.
# See below.
rising_xrange = rising_xrange.to_a.reverse.freeze

puts yrange.sum { |y|
  ydist = y_dists[y]
  remaining_dist = DIST - ydist

  # Binary search for the x boundaries at this Y.
  # Alternative: Binary search the initial bounds,
  # persist them, and only adjust them as needed on future iterations,
  # assuming that the needed adjustments will be small.
  # Required too much work so I'll just search every time.

  # Both bounds:
  # If all x are small enough, the bound is the first element of the array:
  #   xrange.begin for left_x/falling_xrange
  #   xrange.end for right_x/rising_xrange (hence why we reversed it)
  # If no x are small enough, the bound is nil so we continue.
  next 0 unless left_x = falling_xrange.bsearch { |x|
    x_dists[x] < remaining_dist
  }
  next 0 unless right_x = rising_xrange.bsearch { |x|
    x_dists[x] < remaining_dist
  }

  edge_y = y == yrange.begin || y == yrange.end
  edge_x = left_x == xrange.begin || right_x == xrange.end
  puts "DANGER! SAFE ON EDGE #{y} #{left_x}..#{right_x}" if edge_y || edge_x

  # The bounds were inclusive, so we add one more.
  right_x - left_x + 1
}

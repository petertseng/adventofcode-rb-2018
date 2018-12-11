SIZE = 300
MIN_CELL = -5
MAX_CELL = 4

verbose = ARGV.delete("-v")

serial = !ARGV.empty? && ARGV.first.match(/^\d+$/) ? ARGV.first.to_i : 0

power = (0..SIZE).map { |y|
  (0..SIZE).map { |x|
    rack = x + 10
    (((rack * y + serial) * rack) // 100 % 10 || 0) - 5
  }
}

# https://en.wikipedia.org/wiki/Summed-area_table
# sum[y][x] reports the sum of all points above and to the left of (y, x).
# We zero the first row/column because of 0-indexing vs 1-indexing.
sum = Array.new(SIZE) { [0] }
sum.unshift([0] * (SIZE + 1))

(1..SIZE).each { |y|
  (1..SIZE).each { |x|
    sum[y] << power[y][x] + sum[y - 1][x] + sum[y][x - 1] - sum[y - 1][x - 1]
  }
}

# For a square starting at X, Y:
# It would end at X+2, Y+2.
# We would have to subtract values at X-1, Y-1 from the table.
#
# Thus, just shift all values by -1 when iterating to find the max,
# and shift back by +1 when we've found it.
puts (0..(SIZE - 3)).to_a.repeated_permutations(2).max_by { |(x, y)|
  sum[y + 3][x + 3] - sum[y][x + 3] - sum[y + 3][x] + sum[y][x]
}.map(&.succ).join(',')

def guess_max(maxes, sidelen)
  if sidelen == 1
    MAX_CELL
  elsif sidelen % 2 == 0
    maxes[sidelen // 2][0] * 4
  else
    (maxes[sidelen // 2 + 1][0] + maxes[sidelen // 2][0]) * 2 - MIN_CELL
  end
end

maxes = {} of Int32 => Tuple(Int32, Int32, Int32, Int32, Symbol)

(1..SIZE).each { |sidelen|
  guessed_max = guess_max(maxes, sidelen)
  # If we know we can't beat the max, don't bother enumerating all.
  if sidelen > 1 && guessed_max < maxes.each_value.max[0]
    # We might put in a value that is larger than achievable,
    # causing 2N to *not* be doomed when it otherwise would.
    # However, since we choose not to enumerate,
    # this is the best we can do.
    # Empirically, this hasn't caused any problems.
    maxes[sidelen] = {guessed_max, 0, 0, 0, :doomed}
    next
  end

  max_this_size = {MIN_CELL * sidelen * sidelen, 0, 0, 0, :undef}

  valid = (0..(SIZE - sidelen))
  valid.each { |ymin|
    ymax = ymin + sidelen
    ymins = sum[ymin]
    ymaxes = sum[ymax]
    valid.each { |xmin|
      xmax = xmin + sidelen

      power_here = ymaxes[xmax] - ymins[xmax] - ymaxes[xmin] + ymins[xmin]
      max_this_size = {power_here, xmin + 1, ymin + 1, sidelen, :ok} if power_here > max_this_size[0]
    }
  }

  maxes[sidelen] = max_this_size
}

max = maxes.each_value.max
if verbose
  puts max[0]
  not_doomed = (1..300).reject { |k| maxes[k][-1] == :doomed }
  consecutives = 1.step.find { |i| not_doomed[i - 1] != i }.not_nil! - 1
  not_doomed.shift(consecutives)
  puts "Not doomed (#{consecutives + not_doomed.size}): 1-#{consecutives}, #{not_doomed}"
end
puts max.skip(1).first(3).join(',')

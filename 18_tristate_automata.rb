require 'time'

# Nothing ever depends on the count of OPEN,
# so we are safe to make OPEN 0.
# Otherwise, we'd have to number elements 1, 2, 3.
# Not that it matters anyway; either way, space is being wasted.
# (two bits can represent four elements, but we only have three)
OPEN = 0
TREE = 1
LUMBER = 2

# 2 bits per cell, 9 cells in 3x3 neighbourhood,
# arranged in this way:
#  0 -  5: top left , left , bot left
#  6 - 11: top      , self , bot
# 12 - 17: top right, right, bot right
# Move across the array, shifting off the left as we go.
# Index into a lookup table using this 18-bit integer.

BITS_PER_CELL = 2
CELLS_PER_ROW = 3
CELL_MASK = (1 << BITS_PER_CELL) - 1

COL_OFFSET = BITS_PER_CELL * CELLS_PER_ROW

# Where the right column gets inserted
TOP_RIGHT_OFFSET = COL_OFFSET * 2 + BITS_PER_CELL * 2
MID_RIGHT_OFFSET = COL_OFFSET * 2 + BITS_PER_CELL
BOT_RIGHT_OFFSET = COL_OFFSET * 2

ME = 4
NOT_ME = (0...9).to_a - [ME]

verbose = ARGV.delete('-v')

before_lookup = Time.now

# It takes about half a second to build the lookup table,
# but the time it saves makes it worth it!
NEXT_STATE = (1 << 18).times.map { |i|
  trees = 0
  lumber = 0
  NOT_ME.each { |j|
    n = (i >> (j * BITS_PER_CELL)) & CELL_MASK
    if n == TREE
      trees += 1
    elsif n == LUMBER
      lumber += 1
    end
  }
  case (i >> (ME * BITS_PER_CELL)) & CELL_MASK
  when OPEN
    trees >= 3 ? TREE : OPEN
  when TREE
    lumber >= 3 ? LUMBER : TREE
  when LUMBER
    lumber > 0 && trees > 0 ? LUMBER : OPEN
  else
    # Note that 3 is unfortunately a waste of space.
  end
}.freeze

puts "Lookup table in #{Time.now - before_lookup}" if verbose

# Next state resulting from `src` is written into `dest`
def iterate(src, dest)
  dest.each_with_index { |write_row, y|
    top = y == 0 ? nil : src[y - 1]
    mid = src[y]
    bot = src[y + 1]

    # The first element in the row (which has no elements to its left)
    bits = mid[0] << MID_RIGHT_OFFSET
    bits |= top[0] << TOP_RIGHT_OFFSET if top
    bits |= bot[0] << BOT_RIGHT_OFFSET if bot

    (1...write_row.size).each { |right_of_write|
      bits >>= COL_OFFSET
      bits |= top[right_of_write] << TOP_RIGHT_OFFSET if top
      bits |= mid[right_of_write] << MID_RIGHT_OFFSET
      bits |= bot[right_of_write] << BOT_RIGHT_OFFSET if bot
      write_row[right_of_write - 1] = NEXT_STATE[bits]
    }

    # The last element in the row (which has no elements to its right)
    bits >>= COL_OFFSET
    write_row[-1] = NEXT_STATE[bits]
  }
end

def compress(grid)
  # grid.flatten *does* work, of course,
  # but let's see if we can do better.
  grid.map { |r| r.reduce(0) { |acc, cell| acc * 3 + cell } }
end

print_grid = ARGV.delete('-g')
current = ARGF.map { |l|
  l.chomp.each_char.map { |c|
    case c
    when ?.; OPEN
    when ?|; TREE
    when ?#; LUMBER
    else raise "invalid #{c}"
    end
  }
}.freeze

def resources(grid, verbose)
  flat = grid.flatten
  trees = flat.count(TREE)
  lumber = flat.count(LUMBER)
  "#{"#{trees} * #{lumber} = " if verbose}#{trees * lumber}"
end

patterns = {}

buffer = current.map { |row| [nil] * row.size }.freeze

1.step { |t|
  iterate(current, buffer)
  current, buffer = buffer, current

  puts resources(current, verbose) if t == 10

  key = compress(current)

  if (prev = patterns[key])
    cycle_len = t - prev

    # If we stored in `patterns` in a reasonable way,
    # we could just look in `patterns`...
    # instead we'll just iterate more.
    more = (1000000000 - t) % cycle_len
    previous = t + more - cycle_len
    #prev_flat = patterns.reverse_each.find { |k, v| v == previous }[0]

    puts "t=#{t} repeats t=#{prev}. #{more} more cycles needed (or rewind to #{previous})" if verbose

    more.times {
      iterate(current, buffer)
      current, buffer = buffer, current
    }

    puts resources(current, verbose)

    break
  end

  patterns[key] = t
}

current.each { |row|
  puts row.map { |cell|
    case cell
    when OPEN; ?.
    when TREE; ?|
    when LUMBER; ?#
    else raise "Unknown #{cell}"
    end
  }.join
} if print_grid

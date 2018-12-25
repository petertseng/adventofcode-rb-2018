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

def iterate(cells, height, width)
  prev_row_index = 0
  this_row_index = 0
  next_row_index = 0

  new_cells = [0]

  x = 0
  y = 0

  loop {
    if prev_row_index == next_row_index
      # This happens on init, or if some row is empty
      # (causing next_row_index to not increment).
      # At this point, this_row is on the first non-empty row after the gap.

      # There is no previous row, so we'll leave prev_row here.
      # It will be used next time, if the next row isn't empty.
      prev_row_index = this_row_index

      y = cells[this_row_index]
      if y + 1 <= height
        # We need to populate the row before it!
        y += 1
        next_row_index += 1
      else
        # We'll scan this row.
        break if y == 0
        this_row_index += 1

        # Move next_row to the row after this_row.
        next_row_index = cells.index.with_index { |val, idx|
          idx > this_row_index && val >= 0
        }
      end
    elsif y == 1
      # That's all the rows.
      break
    else
      # Move to next row.
      # If any row has the y value we expect,
      # increment its index so that we scan it.
      y -= 1
      prev_row_index += 1 if cells[prev_row_index] == y + 1
      this_row_index += 1 if cells[this_row_index] == y
    end
    next_row_index += 1 if cells[next_row_index] == y - 1 && y > 1

    # Write new row coordinate
    if new_cells.last < 0
      new_cells << y
    else
      new_cells[-1] = y
    end

    neighbours = 0

    loop {
      # Skip to leftmost cell (most-negative value)
      x = [
        cells[prev_row_index],
        cells[this_row_index],
        cells[next_row_index],
      ].min >> 1

      # If all three pointers are at a Y coordinate we are done with this row.
      break if x >= 0

      loop {
        # Add a column to the bitmap, at bit positions 12-17.
        if cells[prev_row_index] >> 1 == x
          neighbours |= (1 << (TOP_RIGHT_OFFSET + (cells[prev_row_index] & 1)))
          prev_row_index += 1
        end
        if cells[this_row_index] >> 1 == x
          neighbours |= (1 << (MID_RIGHT_OFFSET + (cells[this_row_index] & 1)))
          this_row_index += 1
        end
        if cells[next_row_index] >> 1 == x
          neighbours |= (1 << (BOT_RIGHT_OFFSET + (cells[next_row_index] & 1)))
          next_row_index += 1
        end

        next_state = NEXT_STATE[neighbours]
        if next_state != 0 && x > -width
          new_cells << (((x - 1) << 1) | (next_state == LUMBER ? 1 : 0))
        elsif neighbours == 0
          # No neighbours means we should skip some x coordinates.
          break
        end

        # Move right by shifting a column (6 bits) out of the bitmap.
        # So, newest column is bits 12-17, second at 6-11, oldest at 0-5.
        neighbours >>= 6
        x += 1

        if x == 0
          # Checking for x - 1 == -width here is only needed if width == 1
          # But if width == 1, then the single cell has no neighbours.
          # So we won't get to this point. So it's safe not to check.
          next_state = NEXT_STATE[neighbours]
          new_cells << (((x - 1) << 1) | (next_state == LUMBER ? 1 : 0)) if next_state != 0
          break
        end
      }
    }
  }

  # Done with all the rows.
  if new_cells.last < 0
    new_cells << 0
  else
    new_cells[-1] = 0
  end

  new_cells
end

print_grid = ARGV.delete('-g')
points = ARGF.each_line.with_index.with_object(on: []) { |(line, y), h|
  size = line.chomp.size
  h[:width] ||= size
  raise "line #{y} has size #{size} expected #{h[:width]}" if h[:width] != size
  line.each_char.with_index { |char, x|
    h[:on] << [x, y, TREE] if char == ?|
    h[:on] << [x, y, LUMBER] if char == ?#
  }
  h[:height] = y + 1
}

# Coordinates stored in a one-dimensional array in the following format:
# A positive number indicates the Y coordinate of all following cells.
# A negative odd number indicates an X coordinate of lumber.
# A negative even number indicates an X coordinate of a tree.
# Zero ends the array (not strictly necessary, but convenient).
# Y coordinates are descending (100, 99, ..., 0), so that 0 comes last.
# X coordinates are ascending (-100, -99, ..., -1).
# Theoretically X coordinates could be descending too, so it was arbitrary.
current = []
prev_y = nil
points[:on].sort_by { |x, y, _| [-y, -x] }.each { |x, y, type|
  if y != prev_y
    prev_y = y
    current << y + 1
  end
  current << (((-x - 1) << 1) | (type == LUMBER ? 1 : 0))
}
current << 0
width = points[:width]
height = points[:height]

def resources(grid, verbose)
  xs = grid.select(&:negative?)
  trees = xs.count(&:even?)
  lumber = xs.count(&:odd?)
  "#{"#{trees} * #{lumber} = " if verbose}#{trees * lumber}"
end

patterns = {}

1.step { |t|
  current = iterate(current, height, width)

  puts resources(current, verbose) if t == 10

  if (prev = patterns[current])
    cycle_len = t - prev

    more = (1000000000 - t) % cycle_len
    previous = t + more - cycle_len
    prev_state = patterns.reverse_each.find { |k, v| v == previous }[0]

    puts "t=#{t} repeats t=#{prev}. #{more} more cycles needed (or rewind to #{previous})" if verbose

    puts resources(prev_state, verbose)

    break
  end

  patterns[current.freeze] = t
}

def print(current, height, width)
  points = {}
  curry = nil
  current.each { |pt|
    if pt >= 0
      curry = pt
      next
    end

    points[[curry - 1, -(pt >> 1) - 1]] = pt.even? ? TREE : LUMBER
  }
  (0...height).each { |y|
    f.puts (0...width).map { |x|
      case points[[y, x]]
      when TREE; ?|
      when LUMBER; ?#
      else ?.
      end
    }.join
  }
end

print(current, width) if print_grid

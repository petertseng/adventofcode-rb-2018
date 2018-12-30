input = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

grid = Array.new(1000) { Array.new(1000, :free) }
good = input.to_h { |id, _| [id, true] }
clashes = 0

# The astute reader will note that y/x are swapped.
# But since h/w are swapped as well, it doesn't matter.
input.each { |id, y, x, h, w|
  grid[y, h].each { |row|
    (x...(x + w)).each { |xx|
      case (cell = row[xx])
      when :free
        row[xx] = id
      when :clash
        good.delete(id)
      else
        good.delete(id)
        good.delete(cell)
        row[xx] = :clash
        clashes += 1
      end
    }
  }
}

puts clashes
puts good.keys

input = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

grid = Array.new(1000) { Array.new(1000) { [] } }

# The astute reader will note that y/x are swapped.
# But since h/w are swapped as well, it doesn't matter.
input.each { |id, y, x, h, w|
  grid[y, h].each { |row|
    row[x, w].each { |cell|
      cell << id
    }
  }
}

puts grid.sum { |row| row.count { |x| x.size > 1 } }

puts input.select { |id, y, x, h, w|
  grid[y, h].all? { |row|
    row[x, w].all? { |cell|
      cell.size == 1
    }
  }
}.map(&:first)

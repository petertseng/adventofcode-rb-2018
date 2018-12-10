CYCLE = 23

def cycles_needed(n_marbles)
  cycles_needed = n_marbles / CYCLE
  marbles_per_cycle = CYCLE - 2

  adding_cycles = (0..cycles_needed).bsearch { |n|
    marbles_have = marbles_per_cycle * n
    cycles_left = cycles_needed - n
    # Marbles to be removed are at 19, 35, 51, etc... right of current.
    # I'm adding 4 just because I haven't tested the limit thoroughly,
    # so might be off-by-one.
    # I think it needs to include current, so I think 4 is right anyway.
    marbles_needed = cycles_left * (CYCLE - 7) + 4
    marbles_have >= marbles_needed
  }

  [adding_cycles, cycles_needed - adding_cycles]
end

def play(players, n_marbles, verbose: false)
  scores = [0] * players

  adding_cycles, non_adding_cycles = cycles_needed(n_marbles)
  puts "#{adding_cycles} adding cycles, #{non_adding_cycles} non-adding cycles" if verbose

  # Avoid resizes by allocating all space once at the beginning.
  # A linked list solution ostensibly needs value, left, right.
  # However, left is only used when removing.
  # We can identify the marble to removed in another way:
  # The marble to the right of the 18th marble we add per cycle of 23.
  # Therefore, the convention we'll use is:
  # right[i] indicates index of marble the right of marble numbered i.
  # Saves time now that we only need to do half as many pointer updates.
  right = [nil] * (adding_cycles * CYCLE + 1)
  right[0] = 0

  size = right.size

  current = 0

  adding_cycles.times { |cycle|
    base = CYCLE * cycle

    (CYCLE - 1).times { |i|
      marble = base + 1 + i
      # Insert between current.right and current.right.right
      current_right = right[current]
      right[marble] = right[current_right]
      right[current_right] = marble
      current = marble
    }

    marble = base + CYCLE
    removed = right[marble - 5]
    scores[marble % players] += marble + removed
    current = right[marble - 5] = right[removed]

    if verbose
      to_print = current
      print "#{current}, "
      until (to_print = right[to_print]) == current
        print "#{to_print}, "
      end
      puts
    end
  }

  puts "accidentally allocated up to #{right.size} up from #{size}" if right.size != size

  # First marble to remove is 19 in.
  # The rest are at intervals of 16 thereafter.
  removed = current
  3.times { removed = right[removed] }

  non_adding_cycles.times { |cycle|
    16.times { removed = right[removed] }

    marble = CYCLE * (cycle + adding_cycles + 1)
    scores[marble % players] += marble + removed
  }

  scores.max
end

if ARGV.delete('-t')
  play(9, CYCLE * 4, verbose: true)
  all_good = {
    [9, 25]    => 32,
    [10, 1618] => 8317,
    [13, 7999] => 146373,
    [17, 1104] => 2764,
    [21, 6111] => 54718,
    [30, 5807] => 37305,
  }.map { |args, want|
    got = play(*args)
    puts "#{args} should be #{want} not #{got}" if got != want
    got == want
  }.all?
  puts all_good
end

args = if ARGV.size >= 2 && ARGV.all? { |arg| arg.match?(/^\d+$/) }
  ARGV
else
  ARGF.read.scan(/\d+/)
end
players, marbles = args.map(&method(:Integer))

puts play(players, marbles)
puts play(players, marbles * 100)

CYCLE = 23

def play(players, n_marbles, verbose: false)
  scores = [0] * players

  # Avoid resizes by allocating all space once at the beginning.
  left = [nil] * (n_marbles + 1)
  right = [nil] * (n_marbles + 1)

  left[0] = 0
  right[0] = 0

  size = right.size

  current = 0

  (n_marbles / CYCLE).times { |cycle|
    base = CYCLE * cycle

    (CYCLE - 1).times { |i|
      marble = base + 1 + i
      # Insert between current.right and current.right.right
      current_right = right[current]
      current_right_right = right[current_right]
      right[marble] = current_right_right
      left[marble] = current_right
      right[current_right] = marble
      left[current_right_right] = marble
      current = marble
    }

    marble = base + CYCLE
    7.times { current = left[current] }
    scores[marble % players] += marble + current
    current_right = right[current]
    current_left = left[current]
    left[current_right] = current_left
    current = right[current_left] = current_right

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
  puts "accidentally allocated up to #{left.size} up from #{size}" if left.size != size
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

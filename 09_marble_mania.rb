CYCLE = 23

def play(players, n_marbles, verbose: false)
  scores = [0] * players

  # Avoid resizes by allocating all space once at the beginning.
  # The key is to look at the example and the current marble at each line.
  # There's a relationship between the elements to the left and right of current.
  # This solution can easily be seen as analogous to Python solutions using deque#rotate,
  # except using a fixed-size array as the underlying storage.
  # See ephemient's solution in Haskell.
  marbles = [nil] * n_marbles
  marbles[0] = 0

  current = 0
  size = 1

  (n_marbles / CYCLE).times { |cycle|
    base = CYCLE * cycle

    (CYCLE - 1).times { |i|
      marble = base + 1 + i
      # Insertion: current and right-of-current become left-of-current.
      # Note that in this array, subtraction goes to the right,
      # so that we can just use a negative index instead of doing % n_marbles.
      # This saves on a bit of runtime.
      marbles[current - size] = marbles[current]
      current = (current - 1) % n_marbles
      marbles[current - size] = marbles[current]
      marbles[current] = marble
      size += 1
    }

    marble = base + CYCLE
    # Deletion: Current plus five elements to the left (six in total)
    # become right-of-current.
    (1..6).each { |i|
      # current + i >= marbles.size is *never* true because...?
      # I'm not sure, no proof for this.
      # Note that we will always have subtracted 1 from current 22 times,
      # but what if we wrapped around in the last 6 times?
      # For now I'll just print out a warning if I accidentally allocated.
      # It hasn't happened in any test cases.
      marbles[current + i] = marbles[current - size + i]
    }
    scores[marble % players] += marble + marbles[current - size + 7]
    current += 6
    size -= 1

    if verbose
      to_the_right = marbles[[(current - size + 1), 0].max..current]
      remain = size - to_the_right.size
      wrapped = marbles[-remain, remain]
      puts "#{to_the_right.reverse} / #{wrapped.reverse} @ #{current}"
    end
  }

  puts "accidentally allocated up to #{marbles.size} up from #{n_marbles}" if marbles.size != n_marbles
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

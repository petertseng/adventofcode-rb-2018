Circle = Struct.new(:left, :right) do
  def move_left
    if left.empty?
      self.left = right
      self.right = []
    end
    right.unshift(left.pop)
  end

  def move_right
    if right.empty?
      self.right = left
      self.left = []
    end
    left << right.shift
  end

  def insert_left(v)
    left << v
  end

  def delete_left
    (left.empty? ? right : left).pop
  end
end

CYCLE = 23

def play(players, n_marbles, verbose: false)
  scores = [0] * players
  # Convention: Keep the cursor to the right of the current marble.
  circle = Circle.new([0], [])

  (n_marbles / CYCLE).times { |cycle|
    base = CYCLE * cycle

    (CYCLE - 1).times { |i|
      marble = base + 1 + i
      # Because we keep the cursor to the right of the current,
      # and we insert to the left of the cursor,
      # we only need to move right once to insert the marble
      # and have it become the new current.
      # Since 22/23 iterations are of this type, we want this to be fast,
      # and doing only one move_right (instead of two) helps.
      circle.move_right
      circle.insert_left(marble)
    }

    marble = base + CYCLE
    7.times { circle.move_left }
    scores[marble % players] += marble + circle.delete_left
    circle.move_right

    p circle if verbose
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

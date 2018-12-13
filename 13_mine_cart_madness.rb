UP = 0
RIGHT = 1
DOWN = 2
LEFT = 3

class Cart
  attr_reader :pos, :dead

  def initialize(y, x, width, dir)
    @pos = y * width + x
    @width = width
    @dir = dir
    @intersections = 0
    @dead = false
  end

  def move!
    case @dir
    when UP;    @pos -= @width
    when DOWN;  @pos += @width
    when LEFT;  @pos -= 1
    when RIGHT; @pos += 1
    else raise "Unknown direction #{dir}"
    end
  end

  array_of = ->(pairs) {
    # Transform into arrays indexed by current direction.
    pairs.sort_by(&:first).map(&:last).freeze
  }
  FALLING_CURVE = array_of[
    [[UP, LEFT], [RIGHT, DOWN]].flat_map { |x| [x, x.reverse] }
  ]
  RISING_CURVE = array_of[
    [[UP, RIGHT], [LEFT, DOWN]].flat_map { |x| [x, x.reverse] }
  ]
  LEFT_TURN = array_of[[UP, LEFT, DOWN, RIGHT, UP].each_cons(2)]
  RIGHT_TURN = array_of[[UP, RIGHT, DOWN, LEFT, UP].each_cons(2)]

  def turn!(c)
    case c
    when ?\\; @dir = FALLING_CURVE[@dir]
    when ?/;  @dir = RISING_CURVE[@dir]
    when ?+;  @dir = self.class.turn_intersection(@dir, @intersections += 1)
    when ' '; raise "#{self} off the rails at #{@pos.divmod(@width)}"
    end
  end

  def crash!
    @dead = true
  end

  def self.turn_intersection(dir, times)
    case times % 3
    when 1; LEFT_TURN[dir]
    when 2; dir
    when 0; RIGHT_TURN[dir]
    else raise "math is broken for #{times}"
    end
  end
end

INPUT_DIR_REPR = {
  ?^ => UP,
  ?> => RIGHT,
  ?v => DOWN,
  ?< => LEFT,
}.freeze

verbose = ARGV.delete('-v')
track = ARGF.map(&:chomp).map(&:freeze).freeze

width = track.map(&:size).max
uncoord = ->(pos) { pos.divmod(width) }

carts = track.each_with_index.flat_map { |row, y|
  row.each_char.with_index.filter_map { |c, x|
    if (dir = INPUT_DIR_REPR[c])
      Cart.new(y, x, width, dir)
    end
  }
}
puts "WARNING: Even number of carts (#{carts.size})" if carts.size.even?
flat_track = track.map { |l| l.ljust(width, ' ') }.join

first_crash = true

occupied = carts.to_h { |cart| [cart.pos, cart] }

last_crash = 0

1.step { |t|
  carts.sort_by!(&:pos)
  carts.each { |cart|
    # A lower-ID cart moved into this cart's current position
    next if cart.dead

    occupied.delete(cart.pos)

    if (crashed = occupied.delete(cart.move!))
      puts "Crash at #{uncoord[cart.pos]} t=#{t}" if verbose
      if first_crash
        puts uncoord[cart.pos].reverse.join(?,)
        first_crash = false
      end
      cart.crash!
      crashed.crash!
      last_crash = t
      next
    end

    occupied[cart.pos] = cart

    cart.turn!(flat_track[cart.pos])
  }

  carts.reject!(&:dead)

  break if carts.size <= 1

  # Arbitrary limit, but no Advent of Code input comes even close.
  # For example, mine at 20k.
  raise "Gone on too long, t=#{t} #{carts}" if t >= last_crash + 500_000
}

raise 'No carts left???' if carts.empty?
puts uncoord[carts[0].pos].reverse.join(?,)

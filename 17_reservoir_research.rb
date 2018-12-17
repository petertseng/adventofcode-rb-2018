class Reservoir
  attr_reader :ymin, :ymax

  def initialize(clay)
    @clay = clay.each_value(&:freeze).freeze
    @water = Hash.new { |h, k| h[k] = {} }
    @ymin, @ymax = clay.each_key.minmax
  end

  def fill_down(srcy:, srcx:)
    done_drops = {}
    checked_fill_down(srcy: srcy, srcx: srcx, done: done_drops)
  end

  def water_at_rest
    (@ymin..@ymax).sum { |y| @water[y].each_value.count(:rest) }
  end

  def water_reach
    (@ymin..@ymax).sum { |y| @water[y].size }
  end

  def to_s(yrange: (@ymin..@ymax), xrange: nil)
    xrange ||= begin
      xs = @water.each_value.flat_map(&:keys)
      xmin, xmax = xs.minmax
      # Margin of 1 so we can see the limiting walls too.
      ((xmin - 1)..(xmax + 1))
    end

    yrange.map { |y|
      xrange.map { |x|
        water = case w = @water[y][x]
        when :flow; ?|
        when :rest; ?~
        when nil; nil
        else raise "Unknown water #{w} at #{y}, #{x}"
        end

        clay = @clay.dig(y, x) ? ?# : nil

        raise "#{y}, #{x} conflicts: #{clay} and #{water}" if clay && water

        clay || water || ' '
      }.join + " #{y}"
    }.join("\n")
  end

  private

  # Originally, I let each call to this fill just one layer of water,
  # but this causes the water to re-traverse the map every time.
  # Instead, entirely fill all containers we find.
  # Brings runtime down from 6 seconds -> 0.2 seconds.
  def checked_fill_down(srcy:, srcx:, done:)
    # Originally, I didn't have this check,
    # and the last iteration set off a huge chain of recursive calls.
    # (called this function 282k times)
    return if done[[srcy, srcx]]
    done[[srcy, srcx].freeze] = true

    obstacle_below = (srcy..@ymax).find { |y|
      # The code is still correct if we remove the resting water check,
      # but it would have to redo work it already did.
      # So we will consider resting water an obstacle for dropping water.
      @clay.dig(y, srcx) || @water[y][srcx] == :rest
    }

    unless obstacle_below
      puts "Water falls from #{srcy} #{srcx} off screen" if VERBOSE
      (srcy..@ymax).each { |y| @water[y][srcx] = :flow }
      return
    end

    (srcy...obstacle_below).each { |y| @water[y][srcx] = :flow }

    # Start filling upwards, starting from one above that obstacle.
    (obstacle_below - 1).step(by: -1) { |current|
      left_type, leftx   = scout(srcy: current, srcx: srcx, dir: -1)
      right_type, rightx = scout(srcy: current, srcx: srcx, dir: 1)
      range = (leftx + 1)...rightx

      if left_type == :wall && right_type == :wall
        # Walls on either side.
        # Water rests, we move up and do it again.
        range.each { |x| @water[current][x] = :rest }
      else
        # One or both sides lacks a wall.
        # Water flows on this level, and drops on any side lacking a wall.
        range.each { |x| @water[current][x] = :flow }
        puts [
          "Water falls from #{srcy} #{srcx} to #{obstacle_below - 1}",
          "filled up to #{current}",
          "left[#{left_type}@#{leftx}]",
          "right[#{right_type}@#{rightx}]",
        ].join(', ') if VERBOSE
        checked_fill_down(srcy: current, srcx: leftx,  done: done) if left_type == :drop
        checked_fill_down(srcy: current, srcx: rightx, done: done) if right_type == :drop
        break
      end
    }
  end

  def scout(srcy:, srcx:, dir:)
    (srcx + dir).step(by: dir) { |x|
      if @clay.dig(srcy, x)
        return [:wall, x]
      elsif !@clay.dig(srcy + 1, x) && @water[srcy + 1][x] != :rest
        # As in fill_down, water can rest on top of resting water or clay.
        # If neither of those things is below, then it's a drop.
        return [:drop, x]
      end
    }
  end
end

SPRING = 500
VERBOSE = ARGV.delete('-v')
xrange = if ARGV.delete('-x')
  :auto
elsif xarg = ARGV.find { |x| x.start_with?('-x') }
  ARGV.delete(xarg)
  l, r = xarg.scan(/\d+/).map(&:to_i)
  # If it's two numbers, assume it's left/right.
  # If it's one number, assume it's margin around the spring.
  r ? l..r : (SPRING - l)..(SPRING + l)
end

# No default_proc because I'm freezing it,
# so attempts to access should not write.
clay = {}

ARGF.each_line { |line|
  names = line.split(', ').to_h { |elt|
    name, spec = elt.split(?=)
    spec = if spec.include?('..')
      l, r = spec.split('..')
      Integer(l)..Integer(r)
    else
      Integer(spec)..Integer(spec)
    end
    [name, spec]
  }

  names[?y].each { |y|
    clay[y] ||= {}
    names[?x].each { |x|
      clay[y][x] = true
    }
  }
}

reservoir = Reservoir.new(clay)
reservoir.fill_down(srcy: 0, srcx: SPRING)
puts reservoir.water_reach
puts reservoir.water_at_rest

puts reservoir.to_s(xrange: xrange == :auto ? nil : xrange) if xrange

require_relative 'lib/search'

verbose = ARGV.delete('-v')
nums = if ARGV.size >= 3 && ARGV.all? { |arg| arg.match?(/^\d+$/) }
  ARGV
else
  ARGF.read.scan(/\d+/)
end
DEPTH = Integer(nums[0])
TARGX = Integer(nums[1])
TARGY = Integer(nums[2])

ICACHE = {}
LCACHE = {}

def index(x, y)
  ICACHE[x << 20 | y] ||= begin
    if x == 0 && y == 0
      0
    elsif x == TARGX && y == TARGY
      0
    elsif y == 0
      x * 16807
    elsif x == 0
      y * 48271
    else
      level(x - 1, y) * level(x, y - 1)
    end
  end
end

def level(x, y)
  LCACHE[x << 20 | y] ||= (index(x, y) + DEPTH) % 20183
end

puts (0..TARGX).sum { |x| (0..TARGY).sum { |y| level(x, y) % 3 } }

COORD_SIZE = 20
X_OFFSET = 2 + COORD_SIZE
Y_OFFSET = 2
COORD_MASK = (1 << COORD_SIZE) - 1
X_MOVE = 1 << X_OFFSET
Y_MOVE = 1 << Y_OFFSET

TOOL_SWITCH = 7

# Strategic pick: The tool value is equal to the terrain it can't cross.
NEITHER = 0
TORCH = 1
CLIMBING_GEAR = 2

# Creating arrays takes too long
def encode(x, y, tool)
  (x << X_OFFSET) | (y << Y_OFFSET) | tool
end

# A little duplicate code for the decode logic,
# but again trying to avoid creating so many arrays.

neighbours = ->(encoded) {
  x = (encoded >> X_OFFSET) & COORD_MASK
  y = (encoded >> Y_OFFSET) & COORD_MASK
  tool = encoded & 3

  ns = []
  ns << [encoded - X_MOVE, 1] if x > 0 && tool != level(x - 1, y) % 3
  ns << [encoded - Y_MOVE, 1] if y > 0 && tool != level(x, y - 1) % 3
  ns << [encoded + X_MOVE, 1] if tool != level(x + 1, y) % 3
  ns << [encoded + Y_MOVE, 1] if tool != level(x, y + 1) % 3
  type = level(x, y) % 3
  ns << [encode(x, y, 3 - type - tool), TOOL_SWITCH]
  ns
}

heuristic = ->(encoded) {
  x = (encoded >> X_OFFSET) & COORD_MASK
  y = (encoded >> Y_OFFSET) & COORD_MASK
  tool = encoded & 3

  (x - TARGX).abs + (y - TARGY).abs + (tool == TORCH ? 0 : TOOL_SWITCH)
}

raise 'impossible' if level(TARGX, TARGY) % 3 == TORCH

score, path = Search.astar(encode(0, 0, TORCH), neighbours, heuristic, encode(TARGX, TARGY, TORCH), verbose: verbose)

puts score

def fmt_path(path)
  time = -1
  prev_tool = TORCH

  path = path.map { |encoded|
    x = (encoded >> X_OFFSET) & COORD_MASK
    y = (encoded >> Y_OFFSET) & COORD_MASK
    tool = encoded & 3

    time += tool == prev_tool ? 1 : TOOL_SWITCH
    prev_tool = tool

    [time, x, y, level(x, y) % 3, tool]
  }

  widths = path.transpose.map { |xs| xs.map { |x| x.to_s.size }.max }
  fmt = widths.zip([
    '%%%dd',
    '%%%dd',
    '%%%dd',
    '%%%dd',
    '%%%dd',
  ]).map { |w, f| f % w }.join(' ')

  path.map { |p| fmt % p }
end

puts fmt_path(path) if verbose

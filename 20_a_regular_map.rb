require 'set'

def bfs(start, map)
  queue = [start]
  dist = {start => 0}

  while (n = queue.shift)
    y, x = n
    neighbours = [
      [y - 1, x],
      [y + 1, x],
      [y, x - 1],
      [y, x + 1],
    ].select { |nn|
      !dist[nn] && map.include?([n, nn])
    }
    gen = dist[n]
    neighbours.each { |nn| dist[nn] = gen + 1 }
    queue.concat(neighbours)
  end

  dist.values
end

def make_map(regex, map, pos)
  original_pos = pos.freeze

  move_to = ->(new_pos) {
    map << [pos, new_pos].freeze
    map << [new_pos, pos].freeze
    pos = new_pos.freeze
  }

  while (c = regex.shift)
    y, x = pos
    case c
    when ?(; make_map(regex, map, pos)
    when ?); break
    when ?|; pos = original_pos
    when ?N; move_to[[y - 1, x]]
    when ?S; move_to[[y + 1, x]]
    when ?W; move_to[[y, x - 1]]
    when ?E; move_to[[y, x + 1]]
    else raise "What is #{c}?"
    end
  end

  map
end

def explore(regex)
  regex = regex.chars
  # Strip off ^ and $
  # but for convenience (when testing), allow them to be omitted too
  regex.shift if regex[0] == ?^
  regex.pop if regex[-1] == ?$
  map = make_map(regex, Set.new, [0, 0])
  values = bfs([0, 0], map)
  [values.max, values.count { |v| v >= 1000 }]
end

{
  # AOC-provided examples
  '^WNE$' => 3,
  '^ENWWW(NEEE|SSE(EE|N))$' => 10,
  '^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$' => 18,
  '^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$' => 23,
  '^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$' => 31,

  # Some user-provided tests:
  # Two paths to a room:
  '^(E|SEN)$' => 2,
  # Two paths to a room, then into another room:
  '^(E|SSEENNW)S$' => 4,
}.each { |regex, want|
  got, _ = explore(regex)
  puts "NO, #{regex} should be #{want} not #{got}" if want != got
}

puts explore(ARGF.read.chomp)

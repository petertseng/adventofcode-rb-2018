require 'set'

# Branching behaviour that AoC inputs never exhibit:
#
# On a branch, you need to:
# 1. Actually update your position by following the branch
#    (Instead of assuming the branch will come back to the same position)
# 2. Union the positions you end up at from each choice of the branch.
#    (Instead of only taking the last one,
#    which again assumes the last choice is empty)
#
# For AoC inputs it suffices to keep only a single position,
# doing neither of the above two things.
# Levels of brokenness can be checked with the below flags.
BROKEN_FOLLOW = ARGV.delete('--broken-follow')
BROKEN_UNION = ARGV.delete('--broken-union')

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

def make_map(regex, map, poses)
  original_poses = poses.dup

  move = ->(dy, dx) {
    poses.map! { |pos|
      y, x = pos
      new_pos = [y + dy, x + dx].freeze
      map << [pos, new_pos].freeze
      map << [new_pos, pos].freeze
      new_pos
    }
  }

  saved_poses = []

  while (c = regex.shift)
    case c
    when ?(
      # If broken, branches have no effect on our position,
      # so N(E|W)N would leave us only having moved NN rather than {NEN, NWN}.
      r = make_map(regex, map, BROKEN_FOLLOW ? poses.dup : poses)
      _, poses = r unless BROKEN_FOLLOW
    when ?); break
    when ?|
      saved_poses |= poses
      poses = original_poses.dup
    when ?N; move[-1, 0]
    when ?S; move[1, 0]
    when ?W; move[0, -1]
    when ?E; move[0, 1]
    else raise "What is #{c}?"
    end
  end

  # If broken, we only let the last element of a union decide our path,
  # so N(EE|W)N would only remember NWN and forget NEEN
  [map, BROKEN_UNION ? poses : saved_poses | poses]
end

def explore(regex)
  regex = regex.chars
  # Strip off ^ and $
  # but for convenience (when testing), allow them to be omitted too
  regex.shift if regex[0] == ?^
  regex.pop if regex[-1] == ?$
  map, _ = make_map(regex, Set.new, [[0, 0].freeze])
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

  # Some above-mentioned branching behaviours that AoC inputs never exhibit:
  # Detour in the middle
  '^N(E|)N$' => 3,
  # Fork in the middle
  '^N(E|W)N$' => 3,
  # Fork at the start (two paths lead to same place)
  '^(SSS|EEESSSWWW)ENNES$' => 8,
}.each { |regex, want|
  got, _ = explore(regex)
  puts "NO, #{regex} should be #{want} not #{got}" if want != got
}

puts explore(ARGF.read.chomp)

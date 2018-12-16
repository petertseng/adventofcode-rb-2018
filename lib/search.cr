module Search
  def self.path_of(prevs, n)
    path = [n]
    current = n
    while (current = prevs[current])
      path.unshift(current)
    end
    path
  end

  def self.bfs(start, neighbours = nil, goal = nil)
    current_gen = [start]
    prev = {start => nil} of Int32 => Int32?
    goals = [] of Int32

    until current_gen.empty?
      next_gen = [] of Int32
      while (cand = current_gen.shift?)
        goals << cand if goal.has_key?(cand)

        neighbours.call(cand).each { |neigh|
          next if prev.has_key?(neigh)
          prev[neigh] = cand
          next_gen << neigh
        } if goals.empty?
      end
      current_gen = next_gen if goals.empty?
    end

    goals.empty? ? nil : path_of(prev, goals.min)
  end
end

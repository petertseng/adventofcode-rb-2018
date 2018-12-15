module Search
  module_function

  def path_of(prevs, n)
    path = [n]
    current = n
    while (current = prevs[current])
      path.unshift(current)
    end
    path.freeze
  end

  def bfs(start, neighbours:, goal:)
    current_gen = [start]
    prev = {start => nil}
    goals = []

    until current_gen.empty?
      next_gen = []
      while (cand = current_gen.shift)
        goals << cand if goal[cand]

        neighbours[cand].each { |neigh|
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

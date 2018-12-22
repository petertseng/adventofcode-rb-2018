require_relative 'priority_queue'

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

  def astar(start, neighbours, heuristic, goal, verbose: false)
    g_score = Hash.new(1.0 / 0.0)
    g_score[start] = 0

    closed = {}
    open = PriorityQueue.new
    open << [heuristic[start], start]
    prev = {}

    while (_, current = open.pop)
      next if closed[current]
      closed[current] = true

      return [g_score[current], path_of(prev, current)] if current == goal

      neighbours[current].each { |neighbour, cost|
        next if closed[neighbour]
        tentative_g_score = g_score[current] + cost
        next if tentative_g_score >= g_score[neighbour]

        prev[neighbour] = current if verbose
        g_score[neighbour] = tentative_g_score
        open << [tentative_g_score + heuristic[neighbour], neighbour]
      }
    end

    nil
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

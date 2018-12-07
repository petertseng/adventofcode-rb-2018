time_delay = if (targ = ARGV.find { |a| a.start_with?('-t') })
  ARGV.delete(targ)
  Integer(targ[2..-1])
else
  60
end
nworkers = if (narg = ARGV.find { |a| a.start_with?('-n') })
  ARGV.delete(narg)
  Integer(narg[2..-1])
else
  5
end

VERBOSE = ARGV.delete('-v')

def work(deps, parallelism = 1, work_factor = nil)
  remaining = deps.flatten.uniq

  doable = -> {
    # I'm sure a more efficient implementation is possible,
    # (for example, graph-based representation)
    # but I'm not having performance trouble so I don't care.
    remaining.select { |r| deps.none? { |_, y| y == r } }.tap { |x|
      puts "Available tasks: #{x}" if VERBOSE && !x.empty?
    }.min
  }

  goal = remaining.size
  done = ''
  # each element is [task_id, finish_time]
  workers = [nil] * parallelism
  deps = deps.dup

  0.step { |t|
    # Has anyone finished a task?
    #
    # Note that a smart implementation can just skip to next worker finish time.
    # However, just as above, I don't care.
    workers.each_with_index { |(task, finish_time), i|
      next unless finish_time == t
      puts "t=#{t} worker #{i} finishes #{task}" if VERBOSE
      done << task
      workers[i] = nil
      deps.reject! { |x, _| x == task }
    }
    break [done, t] if done.size == goal

    # Assign tasks to anyone free
    workers.each_index { |i|
      next if workers[i]
      break unless (todo = doable[])
      finish_time = t + (work_factor&.+(1 + todo.ord - ?A.ord) || 1)
      puts "t=#{t} assign task #{todo} to #{i}, finishes at #{finish_time}" if VERBOSE
      workers[i] = [todo, finish_time]
      remaining.delete(todo)
    }
  }
end

deps = ARGF.map { |l|
  words = l.split
  raise "bad #{l}" if words[0] != 'Step' || words[6] != 'step'
  [words[1], words[7]].map(&:freeze).freeze
}.freeze

puts work(deps)[0]
puts work(deps, nworkers, time_delay)[1]

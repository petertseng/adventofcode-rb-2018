VERBOSE = ARGV.delete('-v')

input = ARGF.map(&:chomp).map(&:freeze).freeze

guards = Hash.new { |h, k| h[k] = Hash.new(0) }

guard = nil
started_sleeping = nil

input.sort.each { |l|
  last_number = Integer(l.scan(/\d+/).last, 10)
  if l.end_with?('begins shift')
    raise "The previous guard #{guard} didn't wake up?" if started_sleeping
    guard = last_number
  elsif l.end_with?('falls asleep')
    raise "but guard #{guard} was already asleep" if started_sleeping
    started_sleeping = last_number
  elsif l.end_with?('wakes up')
    woke_up = last_number
    (started_sleeping...woke_up).each { |min| guards[guard][min] += 1 }
    started_sleeping = nil
  end
}

raise "The last guard #{guard} didn't wake up?" if started_sleeping

%i(sum max).each { |f|
  id, minutes = guards.max_by { |_, v| v.values.public_send(f) }
  max_minute = minutes.keys.max_by(&minutes)
  puts "#{"#{id} * #{max_minute} = " if VERBOSE}#{id * max_minute}"
}

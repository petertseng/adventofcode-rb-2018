INITIAL = [3, 7].freeze
def converged(scores)
  seqs = []
  return nil if scores.size < 10
  (0...10).each { |start|
    pos = start
    poses = []
    while (score = scores[pos])
      poses << [score, pos]
      pos += 1 + score
    end
    seqs[start] = poses
  }
  minlen = seqs.map(&:size).min
  mismatch_from_right = (0...minlen).find { |i|
    seqs.map { |s| s[-1 - i] }.uniq.size > 1
  }
  mismatch_from_right > 0 ? [seqs, mismatch_from_right] : nil
end

first = 0
second = 1
scores = INITIAL.dup

step = -> {
  scores.concat((scores[first] + scores[second]).digits.reverse)
  first = (first + 1 + scores[first]) % scores.size
  second = (second + 1 + scores[second]) % scores.size
}

# This could take a long time since each call to converged traverses the entire array,
# but luckily it doesn't.
until (seqs, mismatch_from_right = converged(scores))
  (_arbitrary = 10).times { step[] }
end

first_matching_score, first_matching_index = seqs[0].last(mismatch_from_right).first

first = 0
second = 1
scores = INITIAL.dup
step[] until scores.size >= first_matching_index + 1

def write_pos(name, pos, seqs, first_match)
  if pos >= first_match
    track = 'suffix'
    new_pos = pos - first_match
  else
    track_index = seqs.index { |s| s.any? { |_, i| i == pos } }
    track = "prefixes[#{track_index}]"
    new_pos = seqs[track_index].index { |_, i| i == pos }
  end
  puts "# #{name} starts at #{pos}"
  puts "#{name}_on_suffix = #{track == 'suffix'}"
  puts "#{name}_track = #{track}"
  puts "#{name}_pos = #{new_pos}"
end

puts "# generated by #{__FILE__}"
puts "# #{scores.join}"
puts 'prefixes = ['
maxlen = (seqs.map(&:size).max - mismatch_from_right) * 3 + 1
seqs.each_with_index { |s, i|
  s = s.dup
  s.pop(mismatch_from_right)
  puts "  %-#{maxlen}s # #{i}" % ["[#{s.map(&:first).join(', ')}],"]
}
puts '].map(&:freeze).freeze'
puts "suffix = [#{scores.drop(first_matching_index).join(', ')}]"
puts
write_pos('first', first, seqs, first_matching_index)
write_pos('second', second, seqs, first_matching_index)
puts
puts "size = #{scores.size}"
puts "next_write = #{first_matching_score + first_matching_index + 1}"

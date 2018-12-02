VERBOSE = ARGV.delete('-v')

input = ARGF.map(&:chomp).map(&:freeze).freeze

two = 0
three = 0

input.each { |i|
  counts = i.each_char.tally.values
  two += 1 if counts.include?(2)
  three += 1 if counts.include?(3)
}

puts "#{"#{two} * #{three} = " if VERBOSE}#{two * three}"

input.combination(2) { |a, b|
  match = a.each_char.zip(b.each_char).map { |aa, bb| aa if aa == bb }.compact
  (puts match.join; break) if match.size == a.size - 1
}

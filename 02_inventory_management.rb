require 'set'

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

seen = Set.new

# O(k^2 * n) (where k is length of the strings) time solution,
# (assuming that either string slicing or string hashing is O(k) time)
# Rather than the obvious O(k * n^2) time solution of comparing all pairs.
# So pay attention to the relative size of k vs n before choosing this way.
input.each { |s|
  s.size.times { |i|
    pair = [s[0...i], s[(i + 1)..-1]]
    puts pair.join if seen.include?(pair)
    seen << pair
  }
}

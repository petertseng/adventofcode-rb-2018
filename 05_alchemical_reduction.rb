def react(str)
  new_str = String.new(capacity: str.size)
  str.each_char { |c|
    new_str << c
    new_str[-2, 2] = '' if new_str[-2]&.swapcase == c
  }
  new_str
end

input = ARGF.read.chomp.freeze

puts (part1 = react(input.dup).freeze).size
puts (?a..?z).map { |tried_letter|
  react(part1.tr(tried_letter + tried_letter.upcase, '')).size
}.min

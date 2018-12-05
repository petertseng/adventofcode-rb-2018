def react(str)
  str.each_char.with_object(String.new(capacity: str.size)) { |c, new_str|
    new_str << c
    new_str[-2, 2] = '' if new_str[-2]&.swapcase == c
  }
end

input = ARGF.read.chomp.freeze

puts (part1 = react(input.dup).freeze).size
puts (?a..?z).map { |tried_letter|
  react(part1.tr(tried_letter + tried_letter.upcase, '')).size
}.min

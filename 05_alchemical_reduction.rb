def react(str)
  loop {
    break str if (?a..?z).all? { |x|
      [
        str.gsub!(x + x.upcase, ''),
        str.gsub!(x.upcase + x, ''),
      ].none?
    }
  }
end

input = ARGF.read.chomp.freeze

puts (part1 = react(input.dup).freeze).size
puts (?a..?z).map { |tried_letter|
  react(part1.tr(tried_letter + tried_letter.upcase, '')).size
}.min

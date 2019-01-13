INITIAL = [3, 7].freeze

two_only = ARGV.delete('-2')

input = !ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read

unless two_only
  first = 0
  second = 1
  scores = INITIAL.dup
  target = Integer(input)
  until scores.size >= target + 10
    scores.concat((scores[first] + scores[second]).digits.reverse)
    first = (first + 1 + scores[first]) % scores.size
    second = (second + 1 + scores[second]) % scores.size
  end
  puts scores[target, 10].join
end

# Boyer-Moore-Horspool
# http://www-igm.univ-mlv.fr/%7Elecroq/string/node18.html
def bad_char_table(digits)
  digits[0..-2].each_with_index.with_object([digits.size] * 10) { |(d, i), t|
    t[d] = digits.size - i - 1
  }
end

# This code does some bad things solely for the purpose of being fast.
def find(digits)
  first = 0
  second = 1
  scores = INITIAL.dup

  score1 = scores[first]
  score2 = scores[second]

  last_digit = digits[-1]
  bad_chars = bad_char_table(digits).freeze
  next_check = digits.size
  idxs = (2..digits.size).map(&:-@).freeze

  # while true is faster than loop
  # https://github.com/JuanitoFatas/fast-ruby#loop-vs-while-true-code
  while true
    new_score = score1 + score2

    # Normally, you'd write new_scores = new_score >= 10 ? new_score.divmod(10) : [new_score]
    # and then iterate over new_scores.
    # Instead, here we manually unroll that loop.
    # Unfortunately, the fastest way was code duplication.

    if new_score >= 10
      new_score -= 10
      scores << 1
      if scores.size == next_check
        return scores.size - digits.size if last_digit == 1 && idxs.all? { |i| scores[i] == digits[i] }
        next_check += bad_chars[1]
      end
    end

    scores << new_score
    if scores.size == next_check
      return scores.size - digits.size if last_digit == new_score && idxs.all? { |i| scores[i] == digits[i] }
      next_check += bad_chars[new_score]
    end

    unless (score1 = scores[first += 1 + score1])
      first %= scores.size
      score1 = scores[first]
    end
    unless (score2 = scores[second += 1 + score2])
      second %= scores.size
      score2 = scores[second]
    end
  end
end

{
  [5, 1, 5, 8, 9] => 9,
  [0, 1, 2, 4, 5] => 5,
  [9, 2, 5, 1, 0] => 18,
  [5, 9, 4, 1, 4] => 2018,
}.each { |k, want|
  got = find(k)
  puts "#{k.join}: want #{want}, got #{got}" if want != got
}

puts find(input.chars.map(&method(:Integer)))

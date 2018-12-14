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

# This isn't as formally verified as Knuth-Morris-Pratt,
# but I think it should be fine.
# I'm assuming the search pattern is small compared to the digit stream,
# so it's fine if this is not the most efficient.
def state_transitions(digits)
  next_state = Array.new(digits.size) { [0] * 10 }
  digits.each_with_index { |d, i|
    next_state[i][d] = i + 1
    (0..9).each { |wrong_digit|
      next if wrong_digit == d
      prefix = digits.first(i) << wrong_digit
      until prefix.empty?
        if digits[0, prefix.size] == prefix
          next_state[i][wrong_digit] = prefix.size
          break
        end
        prefix.shift
      end
    }
  }
  next_state.freeze
end

# This code does some bad things solely for the purpose of being fast.
def find(digits)
  first = 0
  second = 1
  scores = INITIAL.dup

  state_table = state_transitions(digits)
  good_digits = 0

  score1 = scores[first]
  score2 = scores[second]

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
      good_digits = state_table[good_digits][1]
      return scores.size + 1 - digits.size if good_digits == digits.size
      scores << 1
    end

    good_digits = state_table[good_digits][new_score]
    return scores.size + 1 - digits.size if good_digits == digits.size
    scores << new_score

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

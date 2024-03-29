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
  # Generated by gen14.rb
  # 371010124515891677925107
  prefixes = [
    [3, 1, 1, 4, 9], # 0
    [7, 5, 6, 0],    # 1
    [1, 1, 1, 4, 9], # 2
    [0, 1, 1, 4, 9], # 3
    [1, 1, 4, 9],    # 4
    [0, 1, 4, 9],    # 5
    [1, 4, 9],       # 6
    [2, 1, 8, 1],    # 7
    [4, 9],          # 8
    [5, 6, 0],       # 9
  ].map(&:freeze).freeze
  suffix = [7]

  # first starts at 4
  first_on_suffix = false
  first_track = prefixes[0]
  first_pos = 1
  # second starts at 13
  second_on_suffix = false
  second_track = prefixes[0]
  second_pos = 4

  size = 24
  next_write = 31

  # state_transitions: good_digits -> new_digit -> Integer (new_good_digits)
  # It's expected that we'll then index into state_transitions with new_good_digits.
  #
  # Let's skip that extra indexing and precompute it, with:
  # next_state: good_digits -> new_digit -> Array (new_digit -> Array)
  #
  # As can be seen, this will be a self-referential structure.
  # When the result is nil, we have all the digits.
  next_state = Array.new(digits.size) { [] }
  next_state.zip(state_transitions(digits)) { |dst, src|
    src.each_with_index { |new_good_digits, i|
      dst[i] = next_state[new_good_digits]
    }
  }
  next_state.each(&:freeze).freeze
  state = next_state[0]

  score1 = first_track[first_pos]
  score2 = second_track[second_pos]

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
      return size + 1 - digits.size unless (state = state[1])
      if size == next_write
        suffix << 1
        next_write += 2
      end
      size += 1
    end

    return size + 1 - digits.size unless (state = state[new_score])
    if size == next_write
      suffix << new_score
      next_write += 1 + new_score
    end
    size += 1

    unless (score1 = first_track[first_pos += 1])
      first_pos = 0
      if first_on_suffix
        first_track = prefixes[next_write - size]
        first_on_suffix = false
      else
        first_track = suffix
        first_on_suffix = true
      end
      score1 = first_track[0]
    end
    unless (score2 = second_track[second_pos += 1])
      second_pos = 0
      if second_on_suffix
        second_track = prefixes[next_write - size]
        second_on_suffix = false
      else
        second_track = suffix
        second_on_suffix = true
      end
      score2 = second_track[0]
    end
  end
end

{
  # No longer operative since we start w/ 24 elements.
  #[5, 1, 5, 8, 9] => 9,
  #[0, 1, 2, 4, 5] => 5,
  #[9, 2, 5, 1, 0] => 18,
  [5, 9, 4, 1, 4] => 2018,
}.each { |k, want|
  got = find(k)
  puts "#{k.join}: want #{want}, got #{got}" if want != got
}

puts find(input.chars.map(&method(:Integer)))

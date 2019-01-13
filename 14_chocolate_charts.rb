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

# Boyer-Moore
# http://www-igm.univ-mlv.fr/%7Elecroq/string/node14.html
def suffixes(digits)
  m = digits.size
  suff = Array.new(m, nil)
  suff[-1] = m
  g = m - 1
  f = nil

  (m - 2).downto(0) { |i|
    if i > g && suff[i + m - 1 - f] < i - g
      suff[i] = suff[i + m - 1 - f]
      next
    end

    g = i if i < g
    f = i
    g -= 1 while g >= 0 && digits[g] == digits[g + m - 1 - f]
    suff[i] = f - g
  }

  suff
end

def good_suffix_table(digits)
  suff = suffixes(digits)
  m = digits.size

  bmgs = [m] * m
  j = 0
  (m - 1).downto(0) { |i|
    next unless suff[i] == i + 1
    while j < m - 1 - i
      bmgs[j] = m - 1 - i if bmgs[j] == m
      j += 1
    end
  }

  (0..(m - 2)).each { |i|
    bmgs[m - 1 - suff[i]] = m - 1 - i
  }

  bmgs
end

# This code does some bad things solely for the purpose of being fast.
def find(digits)
  first = 0
  second = 1
  scores = INITIAL.dup

  score1 = scores[first]
  score2 = scores[second]

  bad_chars = bad_char_table(digits).freeze
  good_suffixes = good_suffix_table(digits).freeze
  needle_size = digits.size
  full_match = -needle_size - 1
  next_check = needle_size

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
        i = -1
        i -= 1 while digits[i] == scores[i]
        return scores.size - needle_size if i == full_match
        gsinc = good_suffixes[i + needle_size]
        bcinc = bad_chars[scores[i]] + 1 + i
        next_check += gsinc > bcinc ? gsinc : bcinc
      end
    end

    scores << new_score
    if scores.size == next_check
      i = -1
      i -= 1 while digits[i] == scores[i]
      return scores.size - needle_size if i == full_match
      gsinc = good_suffixes[i + needle_size]
      bcinc = bad_chars[scores[i]] + 1 + i
      next_check += gsinc > bcinc ? gsinc : bcinc
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

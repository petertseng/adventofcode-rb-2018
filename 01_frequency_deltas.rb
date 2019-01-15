input = ARGF.each_line.map(&method(:Integer)).freeze

puts sum = input.sum

if sum == 0
  puts 0
  exit 0
end

# https://www.reddit.com/r/adventofcode/comments/a20646/2018_day_1_solutions/eaukxu5/
# Summary: Track cumulative sum for one cycle through the input.
# Note that all future iterations are offset by the total delta for one cycle.
# The first repeated value *must* be one of the cumulative sums from the first cycle.
tot_freq = 0
cumulative_sums = input.map { |freq| tot_freq += freq }.each_with_index.to_a
# Find the pair of numbers that are congruent to each other modulo `sum`
# and with minimum difference between them.
# (difference directly corresponds to number of iterations, of course)
# In the event of a tie, earlier index in the original array wins.
by_modulus = cumulative_sums.group_by { |x, _| x % sum }
puts by_modulus.values.flat_map { |vals|
  vals.sort.each_cons(2).map { |(prev_val, prev_i), (val, _)|
    [val - prev_val, prev_i, val]
  }
}.min.last

verbose = ARGV.delete('-v')

plants = ARGF.readline("\n\n", chomp: true)
raise "bad plants #{plants}" unless plants.start_with?('initial state:')

bit = {?# => true, ?. => false}.freeze

plants = plants.split(?:).last.strip.each_char.map { |c| bit.fetch(c) }.freeze

rules = ARGF.map { |l|
  l, r = l.split('=>').map(&:strip)
  [l.each_char.map { |c| bit.fetch(c) }.freeze, bit.fetch(r)]
}.freeze

duplicates = rules.group_by(&:first).select { |_, v| v.size > 1 }
raise "duplicate rules: #{duplicates}" unless duplicates.empty?

rules = rules.to_h.freeze

rule_sizes = rules.each_key.map(&:size).uniq
raise "rules not all same size #{rule_sizes}" if rule_sizes.size != 1
raise 'empty must stay empty' if rules[[false] * rule_sizes[0]]

missing_rules = [false, true].repeated_permutation(rule_sizes[0]).to_a - rules.keys
raise "missing rules: #{missing_rules}" unless missing_rules.empty?

# hello 2021 day 20
raise "falses result in true -> infinite plants?" if rules[[false] * rule_sizes[0]]

sum = ->(leftmost) { plants.zip(leftmost.step).sum { |p, i| p ? i : 0 } }
# Arbitrarily choose to stop after this many iterations have same diff:
# Doesn't work in general since some patterns may repeat with period > 1.
# Or something crazy, like:
# https://www.reddit.com/r/adventofcode/comments/a70pde/day_12_subterranean_sustainability_aka_plant
# (Five quadratic equations interleaved)
# But, good enough for Advent of Code.
diffs = [nil] * 10
prev_sum = sum[0]

gens_done = 1.step { |gen|
  plants = ([false] * 4 + plants + [false] * 4).each_cons(5).map(&rules).freeze
  current_sum = sum[-2 * gen]

  diffs.shift
  diffs << current_sum - prev_sum

  prev_sum = current_sum

  if gen == 20
    puts current_sum
    p plants.zip((-2 * gen).step).filter_map { |p, i| i if p } if verbose
  end
  break gen if diffs.uniq.size == 1
}

puts "pattern of #{diffs[0]} detected at #{gens_done - diffs.size}" if verbose
puts prev_sum + diffs[0] * (50 * 10 ** 9 - gens_done)

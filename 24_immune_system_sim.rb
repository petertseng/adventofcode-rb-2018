def effective_power(u)
  u[:num] * u[:dmg]
end

def target_selection(attackers, defenders)
  defenders = defenders.to_h { |d| [d[:id], d] }
  attackers.sort_by { |atk| [-effective_power(atk), -atk[:initiative]] }.each { |attacker|
    chosen_target = defenders.values.max_by { |enemy|
      # Since attacker damage remains constant, just use effectiveness.
      [attacker[:effectiveness][enemy[:id]], effective_power(enemy), enemy[:initiative]]
    }
    chosen_target = nil if chosen_target && attacker[:effectiveness][chosen_target[:id]] == 0
    attacker[:target] = chosen_target
    defenders.delete(chosen_target[:id]) if chosen_target
  }
end

def target_selection_phase(teams)
  target_selection(*teams)
  target_selection(*teams.reverse)
end

def attack_phase(turn_order, verbose: nil)
  any_unit_died = false
  any_group_died = false

  turn_order.each { |attacker|
    next if attacker[:num] <= 0
    next unless (defender = attacker[:target])

    damage_done = effective_power(attacker) * attacker[:effectiveness][defender[:id]]
    units_lost = damage_done / defender[:hp]
    any_unit_died ||= units_lost > 0
    group_died = (defender[:num] -= units_lost) <= 0
    any_group_died ||= group_died
    if verbose&.>=(2)
      dead_comment = group_died ? 'now dead' : "now #{defender[:num]} remaining"
      puts "#{attacker[:team]} #{attacker[:id]} attacks #{defender[:id]} for #{damage_done}, killing #{units_lost} - #{dead_comment}"
    end
  }
  any_group_died ? :group_died : any_unit_died ? :unit_died : :stalemate
end

def battle(teams, boost = 0, verbose: nil)
  teams = teams.map { |t| t.map(&:dup) }
  teams[0].each { |u| u[:dmg] += boost }

  # Turn order never changes, so cache here to avoid sorting so many times.
  # In exchange, we have to delete twice.
  turn_order = teams.flatten.sort_by { |u| -u[:initiative] }

  1.step { |n|
    puts "#{?- * 20} Round #{n} #{?- * 20}" if verbose&.>=(2)
    target_selection_phase(teams)
    case attack_phase(turn_order, verbose: verbose)
    when :stalemate; return :stalemate
    when :group_died
      teams.each { |team| team.reject! { |u| u[:num] <= 0 } }
      turn_order.reject! { |u| u[:num] <= 0 }
      return [:immune, teams[0].map { |e| e[:num] }] if teams[1].empty?
      return [:infect, teams[1].map { |e| e[:num] }] if teams[0].empty?
    end
  }
end

linear = ARGV.delete('-l')
progress = ARGV.delete('-p')
verbose = 1 if ARGV.delete('-v')
verbose = 2 if ARGV.delete('-vv')

current_team = nil
id = 0

teams = ARGF.filter_map { |l|
  nums = l.scan(/-?\d+/).map(&:to_i).freeze
  if nums.empty?
    id = 0
    current_team = l.chomp
    current_team = current_team[0...-1] if current_team.end_with?(?:)
    next
  end

  damage_mod = Hash.new(1)
  if l.include?(?()
    l.split(?().last.split(?)).first.split(?;) { |spec|
      spec = spec.split
      mod = spec[0] == 'weak' ? 2 : spec[0] == 'immune' ? 0 : (raise "Unknown spec #{spec}")
      spec.drop(2).join.split(?,) { |n| damage_mod[n.to_sym] = mod }
    }
  end

  words = l.split
  damage_index = words.rindex('damage')

  raise "illegal non-positive number in #{l}" unless nums.all? { |n| n > 0 }

  {
    id: id += 1,
    num: nums[0],
    hp: nums[1],
    dmg: nums[2],
    initiative: nums[3],
    dmg_mod: damage_mod.freeze,
    dmg_type: words[damage_index - 1].to_sym,
    team: current_team.freeze,
  }
}.group_by { |a| a[:team] }.values_at('Immune System', 'Infection')

[teams, teams.reverse].each { |team1, team2|
  team1.each { |u1|
    # Effectiveness remains the same per enemy; cache it.
    u1[:effectiveness] = ([nil] + team2.map { |u2| u2[:dmg_mod][u1[:dmg_type]] }).freeze
  }
}

team, units = battle(teams, verbose: verbose)
puts "#{team}: #{units}" if verbose
puts units.sum

results = {}

# WARNING! UNSOUND:
# Well, this function isn't guaranteed to be monotonic,
# but my input needs such a large boost (188) compared to others
# (I've seen others needing boosts in the 30s or 20s)
# I kinda need this to make runtimes not completely terrible.
upper_bound = 0.step { |n|
  boost = linear ? n : 1 << n
  team, _ = results[boost] = battle(teams, boost)
  puts "#{boost}: #{team}" if progress
  break boost if team == :immune
}

cutoff = linear ? upper_bound : ((upper_bound / 2)..upper_bound).bsearch { |boost|
  team, _ = results[boost] = battle(teams, boost)
  puts "#{boost}: #{team}" if progress
  team == :immune
}

if verbose
  puts "boost #{cutoff}"
  battle(teams, cutoff, verbose: verbose)
end

team, units = results[cutoff]
puts "#{team}: #{units}" if verbose
puts units.sum

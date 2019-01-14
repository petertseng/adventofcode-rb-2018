def effective_power(u)
  u[:num] * u[:dmg]
end

def target_selection(attackers, defenders)
  defenders = defenders[:units].to_h { |d| [d[:id], d] }
  attackers[:units].sort_by { |atk| [-effective_power(atk), -atk[:initiative]] }.each { |attacker|
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

def attack_phase(turn_order, teams, verbose: nil)
  any_unit_died = false
  any_group_died = false

  turn_order.each { |attacker|
    next if attacker[:num] <= 0
    next unless (defender = attacker[:target])

    damage_done = effective_power(attacker) * attacker[:effectiveness][defender[:id]]
    units_lost = damage_done / defender[:hp]
    any_unit_died ||= units_lost > 0
    group_died = (defender[:num] -= units_lost) <= 0
    if group_died
      # Remove defender from by_damage for each type
      team_by_damage = teams[defender[:team_id]][:by_damage]
      defender[:weak_index].each { |dmg_type, i|
        team_by_damage[dmg_type].delete_at(i)
        team_by_damage[dmg_type].each { |u|
          j = u[:weak_index][dmg_type]
          u[:weak_index][dmg_type] -= 1 if j > i
        }
      }
    elsif units_lost > 0
      # Move defender up in the by_damage for each type
      defender_score = [nil, effective_power(defender), defender[:initiative]]
      team_by_damage = teams[defender[:team_id]][:by_damage]
      defender[:weak_index].each { |dmg_type, i|
        defender_score[0] = defender[:dmg_mod][dmg_type] || 1
        team_by_damage_type = team_by_damage[dmg_type]
        while (u2 = team_by_damage_type[i + 1]) && (defender_score <=> [u2[:dmg_mod][dmg_type] || 1, effective_power(u2), u2[:initiative]]) < 0
          u2[:weak_index][dmg_type] = i
          team_by_damage_type[i] = u2
          i += 1
        end
        defender[:weak_index][dmg_type] = i
        team_by_damage_type[i] = defender
      }
    end
    any_group_died ||= group_died
    if verbose&.>=(2)
      dead_comment = group_died ? 'now dead' : "now #{defender[:num]} remaining"
      puts "#{attacker[:team]} #{attacker[:id]} attacks #{defender[:id]} for #{damage_done}, killing #{units_lost} - #{dead_comment}"
    end
  }
  any_group_died ? :group_died : any_unit_died ? :unit_died : :stalemate
end

def battle(teams, boost = 0, verbose: nil)
  teams = teams.map { |t|
    us = t[:units].map(&:dup)
    us.each { |u| u[:weak_index] = u[:weak_index].dup }
    {
      units: us,
      by_damage: t[:by_damage],
    }
  }
  teams[0][:units].each { |u| u[:dmg] += boost }
  teams[0].tap { |team|
    us = team[:units]
    team[:by_damage].each { |dmg_type, idxs|
      # Need to re-sort because boosting may change effective_power
      idxs.sort_by! { |idx|
        u = us[idx]
        mod = dmg_type ? -u[:dmg_mod][dmg_type] : 1
        [-mod, -effective_power(u), -u[:initiative]]
      }
    }
    us.each_with_index { |u, i|
      u[:weak_index] = (u[:weaknesses] + [nil]).map { |k|
        [k, team[:by_damage][k].index(i)]
      }.to_h
    }
  } if boost > 0
  teams.each { |team|
    us = team[:units]
    team[:by_damage] = team[:by_damage].transform_values { |idxs|
      idxs.map { |idx| us[idx] }
    }
  }

  # Turn order never changes, so cache here to avoid sorting so many times.
  # In exchange, we have to delete twice.
  turn_order = teams.flat_map { |t| t[:units] }.sort_by { |u| -u[:initiative] }

  1.step { |n|
    puts "#{?- * 20} Round #{n} #{?- * 20}" if verbose&.>=(2)

    target_selection_phase(teams)
    case attack_phase(turn_order, teams, verbose: verbose)
    when :stalemate; return :stalemate
    when :group_died
      teams.each { |team| team[:units].reject! { |u| u[:num] <= 0 } }
      turn_order.reject! { |u| u[:num] <= 0 }
      return [:immune, teams[0][:units].map { |e| e[:num] }] if teams[1][:units].empty?
      return [:infect, teams[1][:units].map { |e| e[:num] }] if teams[0][:units].empty?
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

  team_id = {
    'Immune System' => 0,
    'Infection' => 1,
  }.fetch(current_team)

  {
    id: id += 1,
    num: nums[0],
    hp: nums[1],
    dmg: nums[2],
    initiative: nums[3],
    dmg_mod: damage_mod.freeze,
    weaknesses: damage_mod.select { |_, v| v > 1 }.keys.freeze,
    dmg_type: words[damage_index - 1].to_sym,
    team: current_team.freeze,
    team_id: team_id,
  }
}.group_by { |a| a[:team] }.values_at('Immune System', 'Infection')

[teams, teams.reverse].each { |team1, team2|
  team1.each { |u1|
    # Effectiveness remains the same per enemy; cache it.
    u1[:effectiveness] = ([nil] + team2.map { |u2| u2[:dmg_mod][u1[:dmg_type]] }).freeze
  }
}

teams.map! { |team|
  weak_to = Hash.new { |h, k| h[k] = [] }
  team.each_with_index { |u, i|
    u[:weaknesses].each { |k|
      # Just store IDs here - we make them real refs in `battle`
      weak_to[k] << i
    }
    weak_to[nil] << i
  }
  weak_to.each { |dmg_type, idxs|
    idxs.sort_by! { |idx|
      u = team[idx]
      mod = dmg_type ? -u[:dmg_mod][dmg_type] : 1
      [-mod, -effective_power(u), -u[:initiative]]
    }
  }
  team.each_with_index { |u, i|
    u[:weak_index] = (u[:weaknesses] + [nil]).map { |k|
      [k, weak_to[k].index(i)]
    }.to_h
  }

  {
    units: team,
    by_damage: weak_to,
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

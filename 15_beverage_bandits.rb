require_relative 'lib/search'

HP = 200
ATTACK = 3

ELF = 0
GOBLIN = 1
TEAM_NAME = {
  ELF => :Elf,
  GOBLIN => :Goblin,
}.sort_by(&:first).map(&:last).freeze

flags = ARGV.select { |a| a.start_with?(?-) }.map { |a| a[1..-1] }.join
# I'd normally use partition, but ARGF expects the filenames in ARGV.
ARGV.select! { |a| a == ?- || !a.start_with?(?-) }

verbose = flags.include?(?v)
one_only = flags.include?(?1)
two_only = flags.include?(?2)
DEBUG = {
  hp: flags.include?('dh'),
  grid: flags.include?('dg'),
  move: flags.include?('dm'),
  attack: flags.include?('da'),
}
progress = flags.include?(?p)

class Unit
  attr_reader :team, :id, :hp
  attr_accessor :pos

  def initialize(team, id, pos)
    @team = team
    @id = id
    @pos = pos
    @hp = HP
  end

  def attacked(damage)
    (@hp -= damage) > 0 ? :alive : :dead
  end

  def alive?
    @hp > 0
  end

  def to_s(width = nil)
    pos_s = width ? @pos.divmod(width) : @pos
    "#{TEAM_NAME[@team]} #{@id} @ #{pos_s} [#{@hp} HP]"
  end
end

def print_grid(goblins, elves, open, height, width, hp: false)
  occupied = (goblins + elves).to_h { |uu| [uu.pos, uu] }
  team_abbrev = TEAM_NAME.map { |tn| tn.to_s[0] }

  (0...height).each { |y|
    row_hp = []
    (0...width).each { |x|
      coord = y * width + x
      if (occupant = occupied[coord])
        abbrev = team_abbrev[occupant.team]
        row_hp << "#{abbrev}#{occupant.hp}"
        print abbrev
      elsif open[coord]
        print ?.
      else
        print ?#
      end
    }
    puts hp ? ' ' + row_hp.join(', ') : ''
  }
end

def next_to(coord, width)
  [
    coord - width,
    coord - 1,
    coord + 1,
    coord + width,
  ].map(&:freeze).freeze
end

def battle(goblins, elves, open, width, attack: ([ATTACK] * 2).freeze, cant_die: nil)
  if DEBUG[:grid]
    height = open.size / width
    print_this_grid = ->(n) {
      puts n
      print_grid(goblins, elves, open, height, width, hp: DEBUG[:hp])
    }
    print_this_grid['Initial state']
  end
  uncoord = ->(p) { p.divmod(width) } if DEBUG[:move]

  team_of = {
    GOBLIN => goblins,
    ELF => elves,
  }.sort_by(&:first).map(&:last).freeze
  enemy_of = team_of.reverse.freeze

  occupied = (goblins + elves).to_h { |uu| [uu.pos, uu] }
  turn_order = goblins + elves

  1.step { |round|
    turn_order.select!(&:alive?)
    turn_order.sort_by!(&:pos)

    puts "#{?= * 40} round #{round} starting #{?= * 40}" if DEBUG.each_value.any?

    turn_order.each { |current_unit|
      next unless current_unit.alive?

      adj_enemy = next_to(current_unit.pos, width).filter_map { |nt|
        next unless (enemy = occupied[nt])
        enemy if enemy.team != current_unit.team
      }

      # move

      if adj_enemy.empty?
        path = Search.bfs(
          current_unit.pos,
          neighbours: ->(pos) {
            next_to(pos, width).select { |n| open[n] && !occupied[n] }
          },
          goal: _next_to_enemy = enemy_of[current_unit.team].flat_map { |e|
            next_to(e.pos, width)
          }.to_h { |e| [e, true] }
        )

        unless path
          puts "#{current_unit.to_s(width)} can't move." if DEBUG[:move]
          # We don't have an enemy to attack
          # (otherwise we wouldn't have tried to move.)
          next
        end

        # path[0] == unit's current location.

        puts "#{current_unit.to_s(width)} will now move to #{uncoord[path[1]]} (want to go to #{uncoord[path[-1]]})" if DEBUG[:move]

        occupied.delete(current_unit.pos)
        new_pos = path[1]
        current_unit.pos = new_pos
        occupied[new_pos] = current_unit

        # By construction, only the last path element is next to an enemy.
        # So, we'll only be there if path[1] == path[-1] (path.size == 2)
        next if path.size != 2

        adj_enemy = next_to(new_pos, width).filter_map { |nt|
          next unless (enemy = occupied[nt])
          enemy if enemy.team != current_unit.team
        }
      end

      # attack

      target = adj_enemy.min_by { |ae| [ae.hp, ae.pos] }

      attack_str = "#{current_unit.to_s(width)} attacks #{target.to_s(width)}" if DEBUG[:attack]
      if target.attacked(attack[current_unit.team]) == :dead
        puts "#{attack_str}, now dead" if DEBUG[:attack]
        return [:unknown, nil, nil] if cant_die && target.team == cant_die
        occupied.delete(target.pos)
        target_team = team_of[target.team]
        target_team.delete(target)

        if target_team.empty?
          winners = team_of[current_unit.team]

          # Can't look at *current* position for turn order here!
          # Need to consult the original turn order for this round.
          # Scans most of the array, but it's fine since this happens once per battle.
          full_rounds = round - 1
          index_of_attacker = turn_order.index(current_unit)
          teammate_after_attacker = turn_order.drop(index_of_attacker + 1).find { |u|
            u.alive? && u.team == current_unit.team
          }
          if teammate_after_attacker
            last_round_commentary = "game ends when #{teammate_after_attacker.to_s(width)} takes a turn" if DEBUG[:grid]
          else
            last_round_commentary = "#{current_unit.to_s(width)} was last to move this turn" if DEBUG[:grid]
            full_rounds += 1
          end

          print_this_grid["Game over, round #{round} (#{last_round_commentary}: #{full_rounds} full rounds)"] if DEBUG[:grid]

          return [current_unit.team, full_rounds, winners.sum(&:hp)]
        end
      elsif DEBUG[:attack]
        puts "#{attack_str}, now #{target.hp} HP"
      end
    }

    if DEBUG[:hp] && !DEBUG[:grid]
      puts "GOBLIN: #{goblins.map(&:hp)}"
      puts "ELF   : #{elves.map(&:hp)}"
    end

    print_this_grid["After round #{round}"] if DEBUG[:grid]
  }
end

input = ARGF.map(&:chomp).map(&:freeze).freeze
width = input.map(&:size).max

goblins = []
elves = []
open = []

input.each_with_index { |row, y|
  row.each_char.with_index { |cell, x|
    # Using plain ints because creating arrays all the time is slow.
    # Using ints takes 3.2 seconds while using arrays takes 15 seconds.
    coord = y * width + x
    case cell
    when ?G
      goblins << Unit.new(GOBLIN, goblins.size, coord)
      open[coord] = true
    when ?E
      elves << Unit.new(ELF, elves.size, coord)
      open[coord] = true
    when ?.
      open[coord] = true
    when ?#
      open[coord] = false
    else
      raise "unknown cell #{cell} at #{y} #{x}"
    end
  }
}

open.freeze
goblins.each(&:freeze).freeze
elves.each(&:freeze).freeze

require 'time'

t = Time.now

unless two_only
  _, *outcome = battle(goblins.map(&:dup), elves.map(&:dup), open, width)

  p outcome if verbose
  puts outcome.reduce(:*)
  puts "#{Time.now - t} part 1" if progress
end

prev_attacks_to_win = HP

# Note that for my input, a binary search will not work!
# Elves win with no deaths at 19,
# but win with deaths at 20-24.
# Don't want to deal w/ that, just linear search.
# It's not too bad anyway since we stop on first Elf death.
((ATTACK + 1)..(HP + 1)).each { |n|
  raise 'The elves can never win' if n > HP

  attack = {
    GOBLIN => ATTACK,
    ELF => n,
  }.sort_by(&:first).map(&:last).freeze

  # ceil(HP / attack) = turns to win
  # if it's the same as previous, don't recheck.
  # For my input, only skips 18, but useful in general.
  attacks_to_win = HP / n
  attacks_to_win += 1 if n * attacks_to_win < HP
  next if attacks_to_win == prev_attacks_to_win
  prev_attacks_to_win = attacks_to_win

  puts "#{Time.now - t} part 2 attack #{n}" if progress
  winner, *outcome = battle(
    goblins.map(&:dup), elves.map(&:dup), open, width,
    attack: attack, cant_die: ELF,
  )

  if winner == ELF
    p [n] + outcome if verbose
    puts outcome.reduce(:*)
    puts "#{Time.now - t} part 2" if progress
    break
  end
} unless one_only

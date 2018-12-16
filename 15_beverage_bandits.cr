require "option_parser"

require "./lib/search"

HP = 200
ATTACK = 3

ELF = 0
GOBLIN = 1
TEAM_NAME = {
  ELF => :Elf,
  GOBLIN => :Goblin,
}.to_a.sort_by(&.first).map(&.last)

verbose = false
one_only = false
two_only = false
progress = false
p2damage = nil

DEBUG = {
  :grid => false,
  :move => false,
  :attack => false,
  :hp => false,
}
FMT = {
  :unit => "%s%d",
  :join => " ",
}

# I'd try parse(into: h), but hard to translate into Crystal.
OptionParser.parse do |opts|
  opts.banner = "Usage: #{PROGRAM_NAME} [options]"

  opts.on("-v", "--verbose") { verbose = true }
  opts.on("-1", "part 1 only") { one_only = true }
  opts.on("-2", "part 2 only") { two_only = true }
  opts.on("-p", "--progress", "progress and timing") { progress = true }
  opts.on("-d DAMAGE", "--dmg DAMAGE", "specific damage for part 2") { |v|
    p2damage = v.to_i
  }

  opts.on("-g", "--grid", "print grid") { DEBUG[:grid] = true }
  opts.on("-m", "--move", "print moves") { DEBUG[:move] = true }
  opts.on("-a", "--attack", "print attacks") { DEBUG[:attack] = true }
  opts.on("-u", "--hp", "print HP") { DEBUG[:hp] = true }

  opts.on("-f", "--unit-fmt FMT", "format string for units") { |v| FMT[:unit] = v }
  opts.on("-j", "--unit-join S", "joiner for units") { |v| FMT[:join] = v }

  opts.on("-h", "--help") {
    puts opts
    exit
  }
end

class Unit
  getter :team, :id, :hp
  property :pos, :no_move_epoch

  @no_move_epoch: Int32?
  @team: Int32
  @id: Int32
  @pos: Int32

  def initialize(team, id, pos)
    @team = team
    @id = id
    @pos = pos
    @hp = HP
    @no_move_epoch = nil
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

def print_grid(goblins, elves, open, height, width, hp = false)
  occupied = (goblins + elves).to_h { |uu| {uu.pos, uu} }
  team_abbrev = TEAM_NAME.map { |tn| tn.to_s[0] }

  (0...height).each { |y|
    row_hp = [] of String
    (0...width).each { |x|
      coord = y * width + x
      if (occupant = occupied[coord])
        abbrev = team_abbrev[occupant.team]
        row_hp << FMT[:unit] % [abbrev, occupant.hp]
        print abbrev
      elsif open[coord]
        print '.'
      else
        print '#'
      end
    }
    puts hp && !row_hp.empty? ? ' ' + row_hp.join(FMT[:join]) : ""
  }
end

def next_to(coord, width)
  [
    coord - width,
    coord - 1,
    coord + 1,
    coord + width,
  ]
end

def battle(goblins, elves, open, width, attack = ([ATTACK] * 2), cant_die = nil)
    height = open.size / width
    print_this_grid = ->(n: String) {
      puts n
      print_grid(goblins, elves, open, height, width, hp = DEBUG[:hp])
    }
  if DEBUG[:grid]
    print_this_grid.call("Initial state")
  end
  uncoord = ->(p: Int32) { p.divmod(width) }

  # Cache open neighbours of each open cell,
  # which saves a lot of work in BFS.
  # (4.2 seconds -> 2.6 seconds)
  open_neighbours = open.map_with_index { |o, i|
    next [] of Int32 unless o
    next_to(i, width).select { |n| open[n] }
  }

  team_of = {
    GOBLIN => goblins,
    ELF => elves,
  }.to_a.sort_by(&.first).map(&.last)

  occupied = (goblins + elves).to_h { |uu| {uu.pos, uu} }
  turn_order = goblins + elves

  # move_epoch increases when a unit moves or dies,
  # since those are what affect the movement options.
  # Each unit will store the move_epoch when it finds it cannot move,
  # and use it to determine when it doesn't need to recheck.
  move_epoch = 0

  # Cache the set of squares next to each team.
  # (2.6 seconds -> 2.3 seconds)
  next_to = [{} of Int32 => Bool, {} of Int32 => Bool]
  team_move_epoch = [0, 0]
  next_to_updated = [-1, -1]

  1.step { |round|
    turn_order.select!(&.alive?)
    turn_order.sort_by!(&.pos)

    puts "#{"-" * 40} round #{round} starting #{"-" * 40}" if DEBUG.each_value.any?

    turn_order.each { |current_unit|
      next unless current_unit.alive?

      adj_enemy = next_to(current_unit.pos, width).compact_map { |nt|
        next unless (enemy = occupied[nt]?)
        enemy if enemy.team != current_unit.team
      }

      # move

      if adj_enemy.empty?
        # If nothing has changed since this unit last saw it can't move,
        # don't bother retrying the BFS.
        # Cuts runtime to about 0.9x original.
        next if current_unit.no_move_epoch == move_epoch

        # Do we need to update the set of squares next to the enemy team?
        enemy_team = 1 - current_unit.team
        if next_to_updated[enemy_team] < team_move_epoch[enemy_team]
          next_to[enemy_team] = team_of[enemy_team].flat_map { |u|
            open_neighbours[u.pos]
          }.to_h { |e| {e, true} }
          next_to_updated[enemy_team] = team_move_epoch[enemy_team]
        end

        path = Search.bfs(
          current_unit.pos,
          neighbours = ->(pos: Int32) { open_neighbours[pos].reject { |n| occupied[n]? } },
          goal = next_to[enemy_team],
        )

        unless path
          puts "#{current_unit.to_s(width)} can't move." if DEBUG[:move]
          current_unit.no_move_epoch = move_epoch
          # We don't have an enemy to attack
          # (otherwise we wouldn't have tried to move.)
          next
        end

        move_epoch += 1
        # Moving changes the set of squares next to my own team.
        team_move_epoch[current_unit.team] = move_epoch

        # path[0] == unit's current location.

        puts "#{current_unit.to_s(width)} will now move to #{uncoord.call(path[1])} (want to go to #{uncoord.call(path[-1])})" if DEBUG[:move]

        occupied.delete(current_unit.pos)
        new_pos = path[1]
        current_unit.pos = new_pos
        occupied[new_pos] = current_unit

        # By construction, only the last path element is next to an enemy.
        # So, we'll only be there if path[1] == path[-1] (path.size == 2)
        next if path.size != 2

        adj_enemy = next_to(new_pos, width).compact_map { |nt|
          next unless (enemy = occupied[nt]?)
          enemy if enemy.team != current_unit.team
        }
      end

      # attack

      target = adj_enemy.min_by { |ae| [ae.hp, ae.pos] }

      attack_str = "#{current_unit.to_s(width)} attacks #{target.to_s(width)}" if DEBUG[:attack]
      if target.attacked(attack[current_unit.team]) == :dead
        puts "#{attack_str}, now dead" if DEBUG[:attack]
        return {-1, {0, 0}} if cant_die && target.team == cant_die
        occupied.delete(target.pos)
        target_team = team_of[target.team]
        target_team.delete(target)

        move_epoch += 1
        # Dying changes the set of squares next to the dying unit's team.
        team_move_epoch[target.team] = move_epoch

        if target_team.empty?
          winners = team_of[current_unit.team]

          # Can't look at *current* position for turn order here!
          # Need to consult the original turn order for this round.
          # Scans most of the array, but it's fine since this happens once per battle.
          full_rounds = round - 1
          index_of_attacker = turn_order.index(current_unit).not_nil!
          teammate_after_attacker = turn_order.skip(index_of_attacker + 1).find { |u|
            u.alive? && u.team == current_unit.team
          }
          if teammate_after_attacker
            last_round_commentary = "game ends when #{teammate_after_attacker.to_s(width)} takes a turn" if DEBUG[:grid]
          else
            last_round_commentary = "#{current_unit.to_s(width)} was last to move this turn" if DEBUG[:grid]
            full_rounds += 1
          end

          print_this_grid.call("Game over, round #{round} (#{last_round_commentary}: #{full_rounds} full rounds)") if DEBUG[:grid]

          return {current_unit.team, {full_rounds, winners.sum(&.hp)}}
        end
      elsif DEBUG[:attack]
        puts "#{attack_str}, now #{target.hp} HP"
      end
    }

    if DEBUG[:hp] && !DEBUG[:grid]
      puts "GOBLIN: #{goblins.map(&.hp)}"
      puts "ELF   : #{elves.map(&.hp)}"
    end

    print_this_grid.call("After round #{round}") if DEBUG[:grid]
  }

  raise "We never get here"
end

input = ARGF.each_line.map(&.chomp).to_a
width = input.map(&.size).max

goblins = [] of Unit
elves = [] of Unit
open = [false] * (width * input.size)

input.each_with_index { |row, y|
  row.each_char.with_index { |cell, x|
    # Using plain ints because creating arrays all the time is slow.
    # Using ints takes 3.2 seconds while using arrays takes 15 seconds.
    coord = y * width + x
    case cell
    when 'G'
      goblins << Unit.new(GOBLIN, goblins.size, coord)
      open[coord] = true
    when 'E'
      elves << Unit.new(ELF, elves.size, coord)
      open[coord] = true
    when '.'
      open[coord] = true
    when '#'
      open[coord] = false
    else
      raise "unknown cell #{cell} at #{y} #{x}"
    end
  }
}

require "time"

t = Time.utc

unless two_only
  _, outcome = battle(goblins.map(&.dup), elves.map(&.dup), open, width)

  p outcome if verbose
  a, b = outcome
  puts a * b
  puts "#{Time.utc - t} part 1" if progress
end

prev_attacks_to_win = HP

damage_range = p2damage ? p2damage.not_nil!..p2damage.not_nil! : (ATTACK + 1)..(HP + 1)

# Note that for my input, a binary search will not work!
# Elves win with no deaths at 19,
# but win with deaths at 20-24.
# Don't want to deal w/ that, just linear search.
# It's not too bad anyway since we stop on first Elf death.
damage_range.each { |n|
  raise "The elves can never win" if n > HP

  attack = {
    GOBLIN => ATTACK,
    ELF => n,
  }.to_a.sort_by(&.first).map(&.last)

  # ceil(HP / attack) = turns to win
  # if it's the same as previous, don't recheck.
  # For my input, only skips 18, but useful in general.
  attacks_to_win = HP / n
  attacks_to_win += 1 if n * attacks_to_win < HP
  next if attacks_to_win == prev_attacks_to_win
  prev_attacks_to_win = attacks_to_win

  puts "#{Time.utc - t} part 2 attack #{n}" if progress
  winner, outcome = battle(
    goblins.map(&.dup), elves.map(&.dup), open, width,
    attack, cant_die = ELF,
  )

  if winner == ELF
    a, b = outcome
    p({n, a, b}) if verbose
    puts a * b
    puts "#{Time.utc - t} part 2" if progress
    break
  end
} unless one_only

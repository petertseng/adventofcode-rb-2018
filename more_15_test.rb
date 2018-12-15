require 'open3'

_template = [
  [
    'description',
    <<~MAP,
    MAP
    <<~EX,
    EX
  ],
]

t = [
  # Samples from https://adventofcode.com/2018/day/15
  [
    'sample 1',
    <<~MAP,
      #######
      #.G...#
      #...EG#
      #.#.#G#
      #..G#E#
      #.....#
      #######
    MAP
    <<~EX,
      [47, 590]
      27730
      [15, 29, 172]
      4988
    EX
  ],
  [
    'sample 2 (tests ordering in part 2!)',
    <<~MAP,
      #######
      #G..#E#
      #E#E.E#
      #G.##.#
      #...#E#
      #...E.#
      #######
    MAP
    # No expected output for part 2 was given,
    # so I just made it myself.
    <<~EX,
      [37, 982]
      36334
      [4, 28, 1038]
      29064
    EX
  ],
  [
    'sample 3',
    <<~MAP,
      #######
      #E..EG#
      #.#G.E#
      #E.##E#
      #G..#.#
      #..E#.#
      #######
    MAP
    <<~EX,
      [46, 859]
      39514
      [4, 33, 948]
      31284
    EX
  ],
  [
    'sample 4',
    <<~MAP,
      #######
      #E.G#.#
      #.#G..#
      #G.#.G#
      #G..#.#
      #...E.#
      #######
    MAP
    <<~EX,
      [35, 793]
      27755
      [15, 37, 94]
      3478
    EX
  ],
  [
    'sample 5',
    <<~MAP,
      #######
      #.E...#
      #.#..G#
      #.###.#
      #E#G#G#
      #...#G#
      #######
    MAP
    <<~EX,
      [54, 536]
      28944
      [12, 39, 166]
      6474
    EX
  ],
  [
    'sample 6',
    <<~MAP,
      #########
      #G......#
      #.E.#...#
      #..##..G#
      #...##..#
      #...#...#
      #.G...G.#
      #.....G.#
      #########
    MAP
    <<~EX,
      [20, 937]
      18740
      [34, 30, 38]
      1140
    EX
  ],
  # Samples from https://www.reddit.com/r/adventofcode/comments/a6f100/day_15_details_easy_to_be_wrong_on/
  [
    'moving into the square of a unit that died this round does not give you an extra turn',
    <<~MAP,
      ####
      ##E#
      #GG#
      ####
    MAP
    <<~EX,
      [67, 200]
      13400
      [7, 58, 29]
      1682
    EX
  ],
  [
    'moving after being damaged does not heal you',
    <<~MAP,
      #####
      #GG##
      #.###
      #..E#
      #.#G#
      #.E##
      #####
    MAP
    <<~EX,
      [71, 197]
      13987
      [6, 68, 103]
      7004
    EX
  ],
  [
    'order based on target square before first step (34/298 if other way around)',
    <<~MAP,
      #######
      #.E..G#
      #.#####
      #G#####
      #######
    MAP
    <<~EX,
      [34, 301]
      10234
      [10, 41, 23]
      943
    EX
  ],
  [
    'order based on square next to enemy, not enemy itself (34/301 if wrong)',
    <<~MAP,
      #######
      #..E#G#
      #.....#
      #G....#
      #######
    MAP
    <<~EX,
      [36, 295]
      10620
      [9, 47, 8]
      376
    EX
  ],
  [
    'round-end calculation is done on original, not current, position (67 if wrong)',
    <<~MAP,
      ######################
      #...................E#
      #.####################
      #....................#
      ####################.#
      #....................#
      #.####################
      #....................#
      ###.##################
      #EG.#................#
      ######################
    MAP
    <<~EX,
      [66, 202]
      13332
      [4, 50, 253]
      12650
    EX
  ],
]

all_good = true

files = Dir.glob("#{__dir__}/15*.rb")
raise "must have exactly one match of 15*.rb, got #{files}" if files.size != 1
file = files[0]

t.each_with_index { |(desc, map, expect), i|
  out, _ = Open3.capture2('ruby', file, '-v', ?-, stdin_data: map)
  next if out.strip == expect.strip

  all_good = false

  puts "===== test case #{i}: #{desc} ====="
  puts 'map:'
  puts map
  puts 'expected:'
  puts expect
  puts 'got:'
  puts out
}

puts all_good

require 'open3'
require 'time'

inline_t = [
  [
    'example',
    <<~BOTS,
    pos=<10,12,12>, r=2
    pos=<12,14,12>, r=2
    pos=<16,12,12>, r=4
    pos=<14,14,14>, r=6
    pos=<50,50,50>, r=200
    pos=<10,10,10>, r=5
    BOTS
    [12, 12, 12], 5,
  ],
  [
    'big bot far away',
    <<~BOTS,
    pos=<1,1,1>, r=1
    pos=<1000,1000,1000>, r=9999
    pos=<101,100,100>, r=1
    pos=<100,101,100>, r=1
    pos=<100,100,101>, r=1
    BOTS
    [100, 100, 100], 4,
  ],
  [
    'small bot far away',
    <<~BOTS,
    pos=<1,1,1>, r=1
    pos=<1000,1000,1000>, r=9
    pos=<101,100,100>, r=1
    pos=<100,101,100>, r=1
    pos=<100,100,101>, r=1
    BOTS
    [100, 100, 100], 3,
  ],
  [
    'two close vs three far away',
    <<~BOTS,
    pos=<10,10,0>, r=1
    pos=<10,10,1>, r=1
    pos=<-10,100,0>, r=1
    pos=<-10,0,0>, r=1
    pos=<-10,-100,0>, r=1
    BOTS
    [10, 10, 0], 2,
  ],
  [
    'big bots close together',
    <<~BOTS,
    pos=<13,12,12>, r=4
    pos=<12,13,12>, r=4
    pos=<12,12,13>, r=4
    pos=<0,0,0>, r=1
    pos=<1,0,0>, r=1
    pos=<16,16,16>, r=1
    BOTS
    # Various points equally far away, so just check distance:
    33, 3,
  ],
  [
    'anti-clique: any two or three intersect but four do not',
    <<~BOTS,
    pos=<5,6,8>, r=1
    pos=<5,7,7>, r=1
    pos=<6,6,7>, r=1
    pos=<6,7,8>, r=1
    BOTS
    [5, 6, 7], 3,
  ],
]

file_t = {
  82010396 => [[10615635, 41145430, 30249331], 983],
  83779034 => [[11723885, 29873299, 42181850], 986],
  88894457 => [[23449460, 25729347, 39715650], 977],
  100474026 => [[35689633, 20484373, 44300020], 980],
  107272899 => [[57147881, 16615493, 33509525], 976],
  119011326 => [[32906997, 34752562, 51351767], 982],
  # Tricky - flatten would give 93750867
  93750870 => [[22698921, 59279594, 11772355], 985],
  # Tricky - flatten would give 71484640
  71484642 => [[31309240, 15032338, 25143064], 977],
  # Tricky - flatten would give 89915524
  89915526 => [[15972003, 44657553, 29285970], 977],
  # Tricky - flatten would give 85761542
  # x+y+z boundary not on any bot's +/-r
  85761543 => [[34574432, 27408638, 23778473], 970],
}

def check(i, desc, bots, out, expect_pt, expect_count)
  if line_with_at = out.lines.rindex { |l| l.include?(?@) }
    count, point = out.lines[line_with_at].split(?@).map(&:strip)
    dist = out.lines[line_with_at + 1]&.to_i
    count = count.empty? ? nil : Integer(count)
  else
    # Well, the implementation failed to give a count/point.
    # We'll see if they managed to give a distance...
    count = nil
    point = nil
    dist = out.lines[-1]&.to_i
  end

  if expect_pt.is_a?(Array)
    expect_dist = expect_pt.sum(&:abs)
    expect_pt = expect_pt.to_s
  else
    expect_dist = expect_pt
    expect_pt = nil
  end

  errs = [
    ("dist: want #{expect_dist} got #{dist}" if expect_dist != dist) ,
    ("point: want #{expect_pt} got #{point}" if expect_pt&.!=(point.chomp)),
    ("count: want #{expect_count} got #{count}" if expect_count != count),
  ].compact

  return true if errs.empty?

  puts "===== test case #{i}: #{desc} ====="
  puts 'bots:'
  puts bots
  puts errs.join("\n")

  false
end

all_good = true

files = Dir.glob("#{__dir__}/23*.rb")
raise "must have exactly one match of 23*.rb, got #{files}" if files.size != 1
file = files[0]

t = Time.now

inline_t.each_with_index { |(desc, bots, expect_pt, expect_count), i|
  out, _ = Open3.capture2('ruby', file, '-v', ?-, stdin_data: bots)
  all_good = false unless check(i, desc, bots, out, expect_pt, expect_count)
}

puts "inline tests took #{Time.now - t}"

file_t.each_with_index { |(dist, expects), i|
  testfiles = Dir.glob("#{__dir__}/inputs/23/*#{dist}*")
  if testfiles.empty?
    # By AoC request I shouldn't distribute a collection of inputs,
    # so these won't be in the repo, but acquire them from somewhere.
    puts "WARNING: #{dist} not present"
    next
  end
  raise "must have exactly one match of #{dist} got #{testfiles}" if testfiles.size > 1
  t = Time.now
  out, _ = Open3.capture2('ruby', file, '-v', testfiles[0])
  if check(i + inline_t.size, dist, "see #{testfiles[0]}", out, *expects)
    puts "#{dist} pass in #{Time.now - t}"
  else
    all_good = false
    puts "#{dist} fail in #{Time.now - t}"
  end
}

puts all_good

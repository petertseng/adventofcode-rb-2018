instructions = {
  addr: ->(a, b, c, r) { r[c] = r[a] + r[b] },
  addi: ->(a, b, c, r) { r[c] = r[a] + b },
  mulr: ->(a, b, c, r) { r[c] = r[a] * r[b] },
  muli: ->(a, b, c, r) { r[c] = r[a] * b },
  banr: ->(a, b, c, r) { r[c] = r[a] & r[b] },
  bani: ->(a, b, c, r) { r[c] = r[a] & b },
  borr: ->(a, b, c, r) { r[c] = r[a] | r[b] },
  bori: ->(a, b, c, r) { r[c] = r[a] | b },
  setr: ->(a, _, c, r) { r[c] = r[a] },
  seti: ->(a, _, c, r) { r[c] = a },
  gtir: ->(a, b, c, r) { r[c] = a > r[b] ? 1 : 0 },
  gtri: ->(a, b, c, r) { r[c] = r[a] > b ? 1 : 0 },
  gtrr: ->(a, b, c, r) { r[c] = r[a] > r[b] ? 1 : 0 },
  eqir: ->(a, b, c, r) { r[c] = a == r[b] ? 1 : 0 },
  eqri: ->(a, b, c, r) { r[c] = r[a] == b ? 1 : 0 },
  eqrr: ->(a, b, c, r) { r[c] = r[a] == r[b] ? 1 : 0 },
}.freeze

raise 'You forgot an instruction...' if instructions.size != 16

could_be = Array.new(instructions.size) { instructions.keys }

broken = ARGV.delete('--broken')
verbose = ARGV.delete('-v')

puts ARGF.each("\n\n", chomp: true).take_while { |l| !l.empty? }.count { |sample|
  before, op, after = sample.lines
  before = before.scan(/\d+/).map(&:to_i).freeze
  after = after.scan(/\d+/).map(&:to_i).freeze
  opcode, a, b, c = op.split.map(&method(:Integer))

  regs = before.dup

  alike = instructions.select { |_, v|
    # If broken, we let mutations leak out from one inst to the other.
    regs = before.dup unless broken
    begin
      v[a, b, c, regs]
    rescue
      # Actually this line isn't necessary...
      # I did it to defend against registers >= 4
      # but it never happens in input?
      next false
    end
    regs == after
  }
  could_be[opcode] &= alike.keys

  alike.size >= 3
}

could_be.each_with_index { |c, i| puts "#{i} (#{c.size}) -> #{c}" } if verbose

assignments = [nil] * instructions.size
until assignments.all?
  only_one = could_be.index { |a| a.size == 1 }
  raise "I'm not smart enough to do this one: #{could_be}" unless only_one

  assigned = could_be[only_one][0]
  puts "Assign #{only_one} #{assigned}" if verbose
  assignments[only_one] = instructions[assigned]
  could_be.each { |e| e.delete(assigned) }
end

regs = [0, 0, 0, 0]

ARGF.each_line { |l|
  opcode, a, b, c = l.split.map(&method(:Integer))
  assignments[opcode][a, b, c, regs]
}

p verbose ? regs : regs[0]

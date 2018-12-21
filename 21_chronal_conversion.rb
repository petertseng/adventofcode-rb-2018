require_relative 'lib/optimise'

instructions = STANDARD_INSTRUCTIONS.merge(
  # divi a i c sets r[c] to r[a]/i.
  #
  # as a side effect:
  # tmp1 also set to r[a]/i + 1
  # tmp2 set to r[a]/i*i
  # tmp3 = 1
  divi: ->(a, b, c, len, i, tmp1, tmp2, tmp3, regs, ipreg) {
    ans = regs[a] / b

    # Side effects
    regs[tmp1] = ans + 1
    regs[tmp2] = (ans + 1) * b
    regs[tmp3] = 1

    regs[c] = ans

    regs[ipreg] += len - 1
  },
).freeze

rules = [
  {
    pattern: [
      [:seti, 0, :ANY, :i],             # i = 0
      [:addi, :i, 1, :tmp1],            # tmp1 = i + 1
      [:muli, :tmp1, :divisor, :tmp2],  # tmp2 = (i + 1) * divisor
      %i(gtrr tmp2 n tmp3),             # if (i + 1) * divisor > n:
      %i(addr tmp3 IPREG IPREG),
      [:addi, :IPREG, 1, :IPREG],
      %i(seti ENDIP_MINUS_1 ANY IPREG), #   goto finish
      [:addi, :i, 1, :i],               # i += 1
      %i(seti STARTIP ANY IPREG),       # goto START
      %i(setr i ANY dest),              # finish: dest = i
    ],
    unique: %i(i),
    replace: %i(divi n divisor dest LEN i tmp1 tmp2 tmp3),
  },
]

def run(program, jumps: nil)
  regs = [0] * 6

  flow = Hash.new { |h, k| h[k] = Hash.new(0) }
  cycles = 0
  ip = 0

  seen = {}
  prev = nil

  # Nothing in this instruction set should cause a register to be < 0
  # so I'm omitting the regs[ip] >= 0 check.
  # Revisit this if the instruction set changes!
  while (inst = program[ip])
    cycles += 1

    ipreg = inst[:ipreg]
    regs[ipreg] = ip

    inst[:f][*inst[:args], regs, ipreg]

    newip = regs[ipreg] + 1
    flow[ip][newip] += 1
    ip = newip

    # All Advent of Code inputs say `if rX == r0 exit`
    # So check for any pattern that looks like this.
    next unless check = if inst[:op] == :eqrr
      if inst[:args][0] == 0
        regs[inst[:args][1]]
      elsif inst[:args][1] == 0
        regs[inst[:args][0]]
      end
    end

    puts check if seen.empty?
    if seen[check]
      # Since each element of the sequence uniquely determines the next,
      # once we see a repeated element, the sequence continues to repeat.
      # So we show the last element before the repeat.
      puts prev
      break
    end
    prev = check
    seen[check] = true
  end

  if jumps
    puts ?= * 20 + " cycle #{cycles}"
    jump_freq_report(flow, program)
    puts ?= * 20
  end
end

verbose = ARGV.delete('-v')
jumps = ARGV.delete('-j')
slow = ARGV.delete('--slow')

program = parse_asm(ARGF.map(&:split), instructions, verbose: verbose, rules: !slow && rules)

run(program, jumps: jumps)

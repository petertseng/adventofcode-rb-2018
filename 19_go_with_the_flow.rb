require_relative 'lib/optimise'

instructions = STANDARD_INSTRUCTIONS.merge(
  # isfactor candidate n dest: add candidate to dest if candidate is a factor of n.
  #
  # as a side effect:
  # tmp1 is set to candidate * n
  # tmp2 is set to bool(candidate * n == n)
  # i is set to n + 1
  # tmp3 is set to 1
  isfactor: ->(candidate, n, dest, len, i, tmp1, tmp2, tmp3, regs, ipreg) {
    regs[dest] += regs[candidate] if regs[n] % regs[candidate] == 0

    # Side effects
    regs[tmp1] = regs[candidate] * regs[n]
    regs[tmp2] = regs[tmp1] == regs[n] ? 1 : 0
    regs[i] = regs[n] + 1
    regs[tmp3] = 1

    regs[ipreg] += len - 1
  },

  # sumfactors adds the factors of n to dest.
  #
  # as a side effect:
  # all side effects of candidate are applied (where candidate's i is sumfactor's j)
  # i is set to n + 1
  # tmp4 is set to 1
  sumfactors: ->(n, dest, len, i, j, tmp1, tmp2, tmp3, tmp4, regs, ipreg) {
    nval = regs[n]
    (1..(nval ** 0.5)).each { |candidate|
      q, r = nval.divmod(candidate)
      next if r != 0
      regs[dest] += candidate + (q == candidate ? 0 : q)
    }

    # Side effects
    regs[tmp1] = regs[n] * regs[n]
    regs[tmp2] = regs[tmp1] == regs[n] ? 1 : 0
    regs[j] = regs[n] + 1
    regs[tmp3] = 1
    regs[i] = regs[n] + 1
    regs[tmp4] = 1

    regs[ipreg] += len - 1
  },
).freeze

rules = [
  {
    pattern: [
      [:seti, 1, :ANY, :i],         # i = 1
      %i(mulr candidate i tmp1),    # tmp1 = candidate * i
      %i(eqrr tmp1 n tmp2),         # if tmp1 == n:
      %i(addr tmp2 IPREG IPREG),
      [:addi, :IPREG, 1, :IPREG],
      %i(addr candidate dest dest), #   dest += candidate
      [:addi, :i, 1, :i],           # i += 1
      %i(gtrr i n tmp3),            # if i <= n:
      %i(addr IPREG tmp3 IPREG),
      %i(seti STARTIP ANY IPREG),   #   goto START
    ],
    unique: %i(n i candidate dest),
    replace: %i(isfactor candidate n dest LEN i tmp1 tmp2 tmp3),
  },
  {
    pattern: [
      [:seti, 1, :ANY, :i],
      %i(isfactor i n dest ANY j tmp1 tmp2 tmp3),
      [:ANY],
      [:ANY],
      [:ANY],
      [:ANY],
      [:ANY],
      [:ANY],
      [:ANY],
      [:ANY],
      [:ANY],
      [:addi, :i, 1, :i],         # i += 1
      %i(gtrr i n tmp4),          # if i <= n:
      %i(addr tmp4 IPREG IPREG),
      %i(seti STARTIP ANY IPREG), #   goto START
    ],
    unique: %i(n i j dest),
    replace: %i(sumfactors n dest LEN i j tmp1 tmp2 tmp3 tmp4),
  },
]

def run(r0, program, jumps: nil)
  regs = [r0] + ([0] * 5)

  flow = Hash.new { |h, k| h[k] = Hash.new(0) }
  cycles = 0
  ip = 0

  # Nothing in this instruction set should cause a register to be < 0
  # so I'm omitting the regs[ipreg] >= 0 check.
  # Revisit this if the instruction set changes!
  while (inst = program[ip])
    cycles += 1

    ipreg = inst[:ipreg]
    regs[ipreg] = ip

    inst[:f][*inst[:args], regs, ipreg]

    newip = regs[ipreg] + 1
    flow[ip][newip] += 1
    ip = newip
  end

  if jumps
    puts ?= * 20 + " cycle #{cycles}"
    jump_freq_report(flow, program)
    puts ?= * 20
  end

  regs
end

verbose = ARGV.delete('-v')
jumps = ARGV.delete('-j')
slow = ARGV.delete('--slow')

program = parse_asm(ARGF.map(&:split), instructions, verbose: verbose, rules: !slow && rules)

[0, 1].each { |r0|
  regs = run(r0, program, jumps: jumps)
  p verbose ? regs : regs[0]
}

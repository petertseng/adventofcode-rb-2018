STANDARD_INSTRUCTIONS = {
  addr: ->(a, b, c, r, _) { r[c] = r[a] + r[b] },
  addi: ->(a, b, c, r, _) { r[c] = r[a] + b },
  mulr: ->(a, b, c, r, _) { r[c] = r[a] * r[b] },
  muli: ->(a, b, c, r, _) { r[c] = r[a] * b },
  banr: ->(a, b, c, r, _) { r[c] = r[a] & r[b] },
  bani: ->(a, b, c, r, _) { r[c] = r[a] & b },
  borr: ->(a, b, c, r, _) { r[c] = r[a] | r[b] },
  bori: ->(a, b, c, r, _) { r[c] = r[a] | b },
  setr: ->(a, _, c, r, _) { r[c] = r[a] },
  seti: ->(a, _, c, r, _) { r[c] = a },
  gtir: ->(a, b, c, r, _) { r[c] = a > r[b] ? 1 : 0 },
  gtri: ->(a, b, c, r, _) { r[c] = r[a] > b ? 1 : 0 },
  gtrr: ->(a, b, c, r, _) { r[c] = r[a] > r[b] ? 1 : 0 },
  eqir: ->(a, b, c, r, _) { r[c] = a == r[b] ? 1 : 0 },
  eqri: ->(a, b, c, r, _) { r[c] = r[a] == b ? 1 : 0 },
  eqrr: ->(a, b, c, r, _) { r[c] = r[a] == r[b] ? 1 : 0 },
}.freeze

def jump_freq_report(flow, program)
  inst_at = ->(n) { program[n]&.values_at(:op, :args)&.join(' ') || 'halt' }

  flow.each { |from, tos|
    if tos.size == 1
      # No jump, always proceeds to next.
      to1 = tos.keys.first
      next if to1 == from + 1
      puts "#{from} [#{inst_at[from]}] unconditional jump to:"
      puts "    #{tos.values.first}x #{to1} [#{inst_at[to1]}]"
      next
    end

    puts "#{from} [#{inst_at[from]}] branch to:"
    total = tos.each_value.sum.to_f
    tos.sort_by(&:last).reverse_each { |to, freq|
      puts '    %6.2f %7dx %2d [%30s]' % [freq / total * 100, freq, to, inst_at[to]]
    }
  }
end

def parse_asm(input, instructions, rules: nil, verbose: false)
  ipreg = nil

  program = input.filter_map { |op, *args|
    if op == '#ip'
      ipreg = Integer(args.join(' '))
      next
    end
    raise "no ipreg for #{op} #{args.join(' ')}" unless ipreg
    {
      ipreg: ipreg,
      op: op.to_sym,
      args: args.map(&:to_i),
    }
  }

  optimise(program, rules, ipreg, verbose: verbose) if rules

  program.each { |inst|
    inst[:f] = instructions.fetch(inst[:op])
    inst.freeze
  }

  program.freeze
end

def optimise(program, rules, ipreg, verbose: false)
  rules.each { |rule|
    program.each_cons(rule[:pattern].size).with_index { |chunk, i|
      len = rule[:pattern].size
      bindings = {
        LEN: len,
        STARTIP: i,
        ENDIP_MINUS_1: i + len - 2,
        ENDIP: i + len - 1,
      }

      if (bindings = chunk_matches_pattern?(chunk, rule[:pattern], bindings))
        missing_uniques = rule[:unique] - bindings.keys
        raise "Missing uniques #{missing_uniques}" unless missing_uniques.empty?

        replace_inst, *replace_args = rule[:replace]
        puts "Replacement for #{replace_inst} matched at #{i} with #{bindings}" if verbose

        must_be_unique = bindings.values_at(*rule[:unique])
        if must_be_unique.uniq.size != must_be_unique.size
          puts "Unique registers #{rule[:unique]} weren't unique" if verbose
          next
        end

        # hmm, will be weird if ipreg changes in between?
        ipreg = chunk[0][:ipreg]
        program[i] = {
          ipreg: ipreg,
          op: replace_inst,
          args: replace_args.map(&bindings),
        }
      end
    }
  }
end

def chunk_matches_pattern?(chunk, pattern, bindings)
  chunk.zip(pattern) { |inst, (pattern_inst, *pattern_args)|
    next if pattern_inst == :ANY

    return false if inst[:op] != pattern_inst
    raise "Unexpected length #{inst} #{inst[:args]} vs #{pattern_inst} #{pattern_inst}" if inst[:args].size != pattern_args.size

    inst[:args].zip(pattern_args).each { |token, token_pattern|
      case token_pattern
      when :ANY
        # anything matches
      when :IPREG
        # The IP register at this point in time
        return false if token != inst[:ipreg]
      when Integer
        return false if token != token_pattern
      when Symbol
        if (existing_binding = bindings[token_pattern])
          return false if token != existing_binding
        else
          bindings[token_pattern] = token
        end
      else raise "Unknown pattern #{token_pattern} in #{pattern_inst}"
      end
    }
  }

  bindings
end

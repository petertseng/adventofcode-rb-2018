# these f1, f2, f3 produce the same answer;
# just different ways of saying the same thing

def f1(x, v)
  oldv = v | 0x10000
  newv = x
  until oldv == 0
    newv += oldv & 0xff
    newv &= 0xffffff
    newv *= 65899
    newv &= 0xffffff
    oldv /= 256
  end
  newv
end

def f2(x, v)
  (v | 0x10000).digits(256).reduce(x) { |acc, d|
    ((acc + d) * 65899) & 0xffffff
  }
end

def f3(orig_x, v)
  x = orig_x * 65899 ** 3
  [
    x,
    (  v & 0xff)                 * 65899 ** 3,
    (( v & 0xff00)   >> 8)       * 65899 ** 2,
    (((v & 0xff0000) >> 16) | 1) * 65899,
  ].sum & 0xffffff
end

def until_loop(f, x)
  seen = {}
  prev = 0
  1.step { |t|
    curr = f[x, prev]
    if (prev_t = seen[curr])
      return {first: f[x, 0], repeated: curr, t: t, prev_t: prev_t, last: prev}
    end
    seen[curr] = t
    prev = curr
  }
end

x = Integer(File.exist?(ARGV[0]) ? File.readlines(ARGV[0])[8].split[1] : ARGV[0])

ans1 = until_loop(method(:f1), x)
ans2 = until_loop(method(:f2), x)
ans3 = until_loop(method(:f3), x)
raise "disagree #{ans1} #{ans2} #{ans3}" if [ans1, ans2, ans3].uniq.size != 1
puts ans1

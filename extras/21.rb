limit = if (narg = ARGV.find { |a| a.start_with?('-n') })
  ARGV.delete(narg)
  Integer(narg[2..-1])
end

I = ARGV[0]&.to_i || 1765573

MASK = 16777215

seen = {}
check = ->(n) {
  seen[n].tap {
    puts "%d %5d %d %s" % [I, seen.size, n, seen[n]]
    seen[n] = seen.size
  }
}

r4 = 0
loop {
  r5 = r4 | 65536
  r4 = I
  until r5 == 0
    r4 += r5 & 255
    r4 &= MASK
    r4 *= 65899
    r4 &= MASK
    r5 /= 256
  end
  break if check[r4] || limit&.<=(seen.size)
}

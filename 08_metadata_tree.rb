input = ARGF.read.split.map(&method(:Integer)).freeze

# Pass me a block telling me what to do with [child_values, metadata_values]
def val(a, &b)
  n_children = a.shift
  n_metadata = a.shift
  yield(n_children.times.map { val(a, &b) }, a.shift(n_metadata))
end

puts val(input.dup) { |child, meta| child.sum + meta.sum }

puts val(input.dup) { |child, meta|
  # metadata indices are 1-indexed, so just prepend a zero.
  child.unshift(0)
  child.size == 1 ? meta.sum : meta.sum { |x| child[x] || 0 }
}

class PriorityQueue
  def initialize
    @elts = []
  end

  def <<(e)
    i = @elts.size
    until i == 0 || ((parent_v = @elts[parent_i = (i - 1) / 2]) <=> e) < 0
      @elts[i] = parent_v
      i = parent_i
    end
    @elts[i] = e
  end

  def pop
    return nil if @elts.empty?
    return @elts.pop if @elts.size == 1
    @elts[0].tap {
      down(0, @elts.pop)
    }
  end

  private

  def down(i, v)
    while (l_v = @elts[l_i = 2 * i + 1])
      smallest_i = i
      smallest_v = v
      if (l_v <=> smallest_v) < 0
        smallest_i = l_i
        smallest_v = l_v
      end
      if (r_v = @elts[r_i = l_i + 1]) && (r_v <=> smallest_v) < 0
        smallest_i = r_i
        smallest_v = r_v
      end
      break if smallest_i == i
      @elts[i] = smallest_v
      i = smallest_i
    end
    @elts[i] = v
  end
end

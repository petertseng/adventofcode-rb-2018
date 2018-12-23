class PriorityQueue
  def initialize
    @elts = []
    @prio = {}
    @idx = {}
  end

  def []=(e, prio)
    @prio[e] = prio
    i = @idx[e] || @elts.size
    until i == 0 || @prio[(parent_v = @elts[parent_i = (i - 1) / 2])] < prio
      @elts[i] = parent_v
      @idx[parent_v] = i
      i = parent_i
    end
    @elts[i] = e
    @idx[e] = i
  end

  def pop
    return nil if @elts.empty?
    last = @elts.pop
    (@elts[0] || last).tap { |e|
      @idx.delete(e)
      @prio.delete(e)
      down(0, last) unless @elts.empty?
    }
  end

  private

  def down(i, v)
    while (l_v = @elts[l_i = 2 * i + 1])
      smallest_i = i
      smallest_v = v
      smallest_prio = @prio[smallest_v]
      if ((l_prio = @prio[l_v]) <=> smallest_prio) < 0
        smallest_i = l_i
        smallest_v = l_v
        smallest_prio = l_prio
      end
      if (r_v = @elts[r_i = l_i + 1]) && ((r_prio = @prio[r_v]) <=> smallest_prio) < 0
        smallest_i = r_i
        smallest_v = r_v
      end
      break if smallest_i == i
      @elts[i] = smallest_v
      @idx[smallest_v] = i
      i = smallest_i
    end
    @elts[i] = v
    @idx[v] = i
  end
end

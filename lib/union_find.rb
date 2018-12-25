class UnionFind
  def initialize(things)
    @parent = things.to_h { |x| [x, x] }
    @rank = things.to_h { |x| [x, 0] }
  end

  def union(x, y)
    xp = find(x)
    yp = find(y)

    return if xp == yp

    if @rank[xp] < @rank[yp]
      @parent[xp] = yp
    elsif @rank[xp] > @rank[yp]
      @parent[yp] = xp
    else
      @parent[yp] = xp
      @rank[xp] += 1
    end
  end

  def find(x)
    @parent[x] = find(@parent[x]) if @parent[x] != x
    @parent[x]
  end

  def num_sets
    @parent.each_key.count { |k| find(k) == k }
  end
end

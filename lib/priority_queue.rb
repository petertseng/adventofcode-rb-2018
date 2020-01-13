class MonotonePriorityQueue
  def initialize
    @qs = []
    @prio = 0
    @size = 0
  end

  def []=(data, priority)
    raise "non-monotonic add #{priority} vs #{@prio}" if priority < @prio
    (@qs[priority] ||= []) << data
    @size += 1
  end

  def pop
    return nil if @size == 0
    @prio += 1 until (q = @qs[@prio]) && !q.empty?
    @size -= 1
    q.pop
  end
end

class PriorityQueue
  # http://www.cs.cmu.edu/afs/cs.cmu.edu/user/sleator/www/papers/pairing-heaps.pdf
  class PairingTree
    attr_reader :data
    attr_accessor :priority, :left_child, :prev, :next

    def initialize(data, priority)
      @data = data
      @priority = priority
      @left_child = nil
      # parent if left child, otherwise left sibling
      @prev = nil
      @next = nil
    end

    def to_s
      "#{@data} @ #{@priority}"
    end
  end

  def initialize
    @root = nil
    @existing = {}
  end

  def []=(data, priority)
    if (existing = @existing[data])
      decrease_key(existing, priority) if (priority <=> existing.priority) < 0
    else
      @existing[data] = insert(data, priority)
    end
    priority
  end

  def pop(with_priority: false)
    return nil unless @root
    @existing.delete(@root.data)
    removed = @root
    @root = merge_pairs(@root.left_child)
    with_priority ? [removed.data, removed.priority] : removed.data
  end

  def dump
    @existing.each { |k, v| puts "#{k}: #{v}" }
  end

  private

  # Insert node into this tree
  def insert(data, priority)
    PairingTree.new(data, priority).tap { |node| @root = merge(@root, node) }
  end

  def decrease_key(node, priority)
    node.priority = priority
    return if node == @root

    # I don't think we know for sure whether we are violating the heap,
    # so we'll just do it unconditionally???

    # Remove or detach...?????
    # Which is correct for efficiency?
    # Doesn't seem to make a difference here.
    detach_tree(node)
    @root = merge(@root, node)
  end

  # Removes a node from the tree,
  # reintegrating its children.
  def remove(node)
    detach_tree(node)
    children = merge_pairs(node.left_child)
    node.left_child = nil
    @root = merge(@root, children)
  end

  # Detaches the node from its relatives,
  # taking its children with it
  def detach_tree(node)
    is_left_child = node.prev.left_child == node
    right_sibling = node.next
    if is_left_child
      parent = node.prev
      parent.left_child = right_sibling
      right_sibling.prev = parent if right_sibling
    else
      left_sibling = node.prev
      left_sibling.next = right_sibling
      right_sibling.prev = left_sibling if right_sibling
    end
    node.next = nil
    node.prev = nil
  end

  # Merge the list of children starting at first_child
  def merge_pairs(first_child)
    return nil if first_child.nil?
    first_child.prev = nil
    return first_child unless (second_child = first_child.next)
    third_child = second_child.next
    first_child.next = nil
    second_child.prev = nil
    second_child.next = nil
    merge(merge(first_child, second_child), merge_pairs(third_child))
  end

  # Merge two trees
  def merge(t1, t2)
    return t2 if t1.nil?
    return t1 if t2.nil?
    if (t1.priority <=> t2.priority) < 0
      t2.next = t1.left_child
      t2.next.prev = t2 if t2.next
      t1.left_child = t2
      t2.prev = t1
    else
      t1.next = t2.left_child
      t1.next.prev = t1 if t1.next
      t2.left_child = t1
      t1.prev = t2
    end
  end
end

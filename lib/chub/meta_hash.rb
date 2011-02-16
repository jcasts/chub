class Chub

  ##
  # Wraps Hash instances with metadata.

  class MetaHash < MetaNode

    ##
    # Create a new MetaHash and assign metadata to all child keys and nodes.

    def initialize hash, meta=nil
      super

      hash.keys.each{|k| MetaNode.build k, meta unless MetaNode === k}
      hash.values.each{|v| MetaNode.build v, meta unless MetaNode === v}
    end


    ##
    # Access a value of the wrapped hash.

    def [] key
      @value.each{|k,v| return v if k == key}
    end


    ##
    # Assign a value of the wrapped hash.

    def []= key, val
      @value.each{|k,v| @value[k] = val and return if k == key}
    end


    ##
    # Apply the meta value to self, and recursively to keys and children.

    def meta= val
      @value.each do |k, v|
        k.meta = val if k.respond_to? :meta=
        v.meta = val if v.respond_to? :meta=
      end

      @meta = val
    end


    ##
    # Merge with and modify the wrapped hash.

    def merge! hash
      hash.each do |k,v|
        key = @value.keys.find{|vk| vk == k || k == vk } || k
        @value.delete key
        @value[k] = v
      end

      self
    end


    ##
    # Create a new MetaHash merged with the given hash or metahash.

    def merge hash
      clone = @value.dup
      hash.each do |k,v|
        key = clone.keys.find{|vk| vk == k || k == vk } || k
        clone.delete key
        clone[k] = v
      end

      clone
    end


    ##
    # Returns the child metadata with the most recent change.

    def meta
      @meta
    end


    ##
    # Strips MetaNode wrapper from the value and calls to_value
    # on all hash elements.

    def to_value
      clone = Hash.new

      @value.each do |k, v|
        key = k.respond_to?(:to_value) ? k.to_value : k
        val = v.respond_to?(:to_value) ? v.to_value : v

        clone[key] = val
      end

      clone
    end
  end
end

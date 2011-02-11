class Chub

  ##
  # Wraps Hash instances with metadata.

  class MetaHash < MetaNode

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
      meta     = nil
      path_key = nil

      @value.each do |key, val|
        if val.respond_to? :meta
          if !meta ||
            meta && val.meta && val.meta[:updated_at] > meta[:updated_at]
            meta = val.meta.dup
            path_key = key
          end
        end

        if key.respond_to? :meta
          if !meta ||
            meta && val.meta && key.meta[:updated_at] > meta[:updated_at]
            meta = key.meta.dup
          end
        end
      end

      (meta[:path] ||= []).unshift path_key if meta && path_key

      meta
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

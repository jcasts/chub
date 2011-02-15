class Chub

  ##
  # Wraps Array instances with metadata.

  class MetaArray < MetaNode

    ##
    # Create a new MetaArray and assign metadata to all child keys and nodes.

    def initialize arr, meta=nil
      super
      arr.each{|v| MetaNode.build v, meta unless MetaNode === v}
    end


    ##
    # Return the index of a data object or meta node.

    def index obj
      @value.each do |v|
        return true if v == obj || v.to_value == obj
      end
    end


    ##
    # Returns the child metadata with the most recent change.

    def meta
      meta     = nil
      path_key = nil

      @value.each_with_index do |val, i|
        next unless val.respond_to? :meta

        meta = val.meta.dup and path_key = i if !meta ||
          meta && val.meta && val.meta[:timestamp] > meta[:timestamp]
      end

      (meta[:path] ||= []).unshift path_key if meta && path_key

      meta
    end


    ##
    # Apply the meta value to self, and recursively to children.

    def meta= val
      @value.each do |v|
        v.meta = val if v.respond_to? :meta=
      end

      @meta = val
    end


    ##
    # Strips MetaNode wrapper from the value and calls to_value
    # on all array elements.

    def to_value
      @value.map{|v| v.respond_to?(:to_value) ? v.to_value : v }
    end
  end
end

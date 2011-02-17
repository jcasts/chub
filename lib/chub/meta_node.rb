class Chub

  ##
  # Simple wrapper class to assign metadata to object instances.

  class MetaNode

    ##
    # Creates a new Meta object based on whether the value is a
    # Hash, Array, or other Object.
    #
    # If the value is a Hash or an Array, the metadata will be applied
    # recursively.

    def self.build value, meta=nil
      case value
      when Hash  then MetaHash.new value, meta
      when Array then MetaArray.new value, meta
      else
        new value, meta
      end
    end


    # The object to assign metadata to.
    attr_accessor :value


    ##
    # Create a new MetaNode with the value to wrap and optional metadata.

    def initialize value, meta=nil
      @value = value
      @meta  = meta
    end


    ##
    # Checks for equality against the value attribute.

    def == obj
      case obj
      when MetaNode then obj.value == @value
      else
        @value == obj
      end
    end


    ##
    # Reader for the meta attribute.
    # Overridden in MetaArray and MetaHash classes.

    def meta
      @meta
    end


    ##
    # Writter for the meta attribute.
    # Overridden in MetaArray and MetaHash classes.

    def meta= val
      @meta = val
    end


    %w{to_s to_i to_f to_sym inspect}.each do |meth|
      class_eval "def #{meth}; @value.#{meth}; end"
    end


    ##
    # Sends non-defined methods to the value attribute

    def method_missing name, *args, &block
      @value.send name, *args, &block
    end


    ##
    # Accessor for the value attribute.
    # Overridden in MetaArray and MetaHash classes.

    def to_value
      @value
    end


    ##
    # Output @value yaml string.

    def to_yaml
      self.to_value.to_yaml
    end
  end
end


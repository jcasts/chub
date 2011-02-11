class Chub

  ##
  # Simple wrapper class to assign metadata to object instances.

  class MetaNode


    # The object to assign metadata to.
    attr_reader :value

    # The metadata assigned to the wrapped object.
    attr_writer :meta

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
    # Accessor for the meta attribute.
    # Overridden in MetaArray and MetaHash classes.

    def meta
      @meta
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


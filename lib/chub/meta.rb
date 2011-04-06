class Chub

  class Meta

    ##
    # Creates a new Meta object from a marshalled data structure.

    def self.new_from data
      inst = new nil
      inst.data = data
      inst
    end


    ##
    # Recursively assigns the meta data to the data object by building a
    # marshalled Meta data structure.

    def self.assign_meta data, meta
      new_data = nil

      case data
      when Array
        new_data = []
        data.each do |val|
          new_data << assign_meta(val, meta)
        end

      when Hash
        new_data = {}
        data.each do |key, val|
          new_data[key] = assign_meta(val, meta)
        end

      else
        new_data = data
      end

      [new_data, meta]
    end


    attr_accessor :data


    ##
    # Builds a new Meta object from the given data structure and meta info.
    # Meta data structure follows this format where data_item is any
    # data structure. Each child element of data_item gets assigned meta data.
    #   [data_item, meta_data]

    def initialize data=nil, meta=nil
      @data = assign_meta data, meta
    end


    ##
    # Gets the data at the given key and returns a new meta instance

    def [] key
      self.class.new_from @data[0][key]
    end


    ##
    # Assigns the value to the given key. If no metadata is present for that
    # key, assigns the root meta.

    def []= key, val
      self.set key, val
    end


    ##
    # Iterates over each data item and yields a Meta instance.

    def each
      @data[0].each do |*args|
        args[-1] = self.class.new args[-1]
        yield(*args) if block_given?
      end
    end


    ##
    # Returns the meta data for this object.

    def metadata
      @data[1]
    end


    ##
    # Returns the original object that metadata was assigned to.

    def value
      data_value = nil

      case @data[0]
      when Hash
        data_value = {}
        @data[0].each do |key, val|
          child = self.class.new_from val
          data_value[key] = child.value
        end

      when Array
        data_value = []
        @data[0].each do |val|
          child = self.class.new_from val
          data_value << child.value
        end

      else
        data_value = @data[0]
      end

      data_value
    end


    ##
    # Assigns val to the given key, with optional metadata. If no metadata is
    # given and value is not a Meta object, uses the root meta.

    def set key, val, meta=nil
      if self.class === val && meta.nil?
        val = val.marshal
      else
        val = val.value if self.class === val
        val = self.class.assign_meta val, @data[1]
      end

      @data[0][key] = val
    end


    ##
    # Sets the data at a given path to val.
    # Raises a PathNotFound error if a path item other than the last element
    # is not found.
    # Raises an ArgumentError if a path already exists with a non matching
    # datatype.

    def set_path path, val, meta=nil
    end


    ##
    # Acts like Meta#set_path but will create the necessary data structures
    # to accomodate missing path items (Arrays for numbers, otherwise Hashes).
    #   m = Meta.new :foo => "one", :bar => [3,2,1]
    #   m.set_path! [:bar, 5, :foobar], "newval"
    #   m.value
    #   #=> {:foo => "one", :bar => [3,2,1,nil,nil,{:foobar => "newval"}]}
    #
    #   m = Meta.new :foo => "one", :bar => [3,2,1]
    #   m.set_path! [:foo, :foobar], "newval"
    #   m.value
    #   #=> {:foo => {:foobar => "newval"}, :bar => [3,2,1]}

    def set_path! path, val, meta=nil
    end


    ##
    # Merges a Meta object with this one and returns a new Meta object.

    def merge meta_obj
      raise ArgumentError,
        "Expected type #{self.class} but got #{meta_obj.class}" unless
          self.class === meta_obj

      # TODO: implement merge!
    end


    ##
    # Outputs a data structure representation of the meta instance.

    def marshal
      @data.dup
    end
  end
end

class Chub

  class Document

    class InvalidPathError < Exception; end

    ##
    # Creates a new Document object from a marshalled data structure.

    def self.new_from data
      inst = self.new
      inst.data = data
      inst
    end


    ##
    # Recursively assigns the meta data to the data object by building a
    # marshalled Document data structure.

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
    # Builds a new Document object from the given data structure and meta info.
    # Document data structure follows this format where data_item is any
    # data structure. Each child element of data_item gets assigned meta data.
    #   [data_item, meta_data]

    def initialize data=nil, meta=nil
      @data = self.class.assign_meta data, meta
    end


    ##
    # Gets the data at the given key and returns a new meta instance

    def [] key
      if Hash === @data[0] && @data[0].has_key?(key) ||
         Array === @data[0] && Fixnum === key && key < @data[0].length

        self.class.new_from @data[0][key]
      end
    end


    ##
    # Assigns the value to the given key. If no metadata is present for that
    # key, assigns the root meta.

    def []= key, val
      self.set key, val
    end


    ##
    # Iterates over each data item and yields a Document instance.

    def each &block
      case @data[0]
      when Array
        @data[0].each_index do |i|
          yield i, self[i]
        end

      when Hash
        @data[0].keys.each do |k|
          yield k, self[k]
        end

      else
        @data[0].each &block
      end
    end


    ##
    # Outputs a data structure representation of the meta instance.

    def marshal
      @data.dup
    end


    ##
    # Merges a Document object with this one and returns a new Document object.
    # Merge will fail and return self if either Document object's root data
    # is not an Array or Hash.

    def merge doc
      new_data = @data[0].dup rescue @data[0]
      self.class.new_from([new_data, @data[1]]).merge! doc
    end


    ##
    # Same as Document#merge but modifies the Document instance.

    def merge! doc
      raise ArgumentError,
        "Expected type #{self.class} but got #{doc.class}" unless
          self.class === doc

      return self unless (Array === @data[0] || Hash === @data[0]) &&
                         (Array === doc.data[0] || Hash === doc.data[0])

      if Array === @data[0] && Array === doc.data[0]
        len = doc.data[0].length
        @data[0][0...len] = doc.data[0]

      else
        @data[0] = @data[0].to_hash.merge doc.data[0].to_hash
      end

      self
    end


    ##
    # Returns the meta data for this object.

    def metadata
      @data[1]
    end


    ##
    # Assigns val to the given key, with optional metadata. If no metadata is
    # given and value is not a Document object, uses the root meta.

    def set key, val, meta=nil
      if self.class === val && meta.nil?
        val = val.marshal
      else
        val    = val.value if self.class === val
        meta ||= @data[1]
        val    = self.class.assign_meta val, meta
      end

      @data[0][key] = val
    end


    ##
    # Sets the data at a given path Array to val.
    # Raises a InvalidPathError error if a path item other than the last element
    # is not found.
    # Raises a TypeError if a path already exists with a non matching
    # datatype (e.g. using a String as an Array index).

    def set_path path, val, meta=nil
      prev_key  = nil

      set_path! path, val, meta do |curr_data, k, meta|
        prev_key = k

        if curr_data[0] && !(Hash === curr_data[0] || Array === curr_data[0])
          raise InvalidPathError,
            "Bad path #{path.inspect} at '#{prev_key}' for " +
              curr_data[0].class.to_s
        end
      end
    end


    ##
    # Acts like Document#set_path but will create or modify the necessary data
    # structures to accomodate missing path items
    # (Arrays for numbers, otherwise Hashes).
    #
    #   m = Document.new :foo => "one", :bar => [3,2,1]
    #   m.set_path! [:bar, 5, :new], "newval"
    #   m.value
    #   #=> {:foo => "one", :bar => [3, 2, 1, nil, nil, {:new => "newval"}]}
    #
    #   m = Document.new :foo => "one", :bar => [3,2,1]
    #   m.set_path! [:foo, :new], "newval"
    #   m.value
    #   #=> {:foo => {:new => "newval"}, :bar => [3, 2, 1]}
    #
    #   m = Document.new :foo => "one", :bar => [3, 2, 1]
    #   m.set_path! [:bar, :new], "newval"
    #   m.value
    #   #=> {:foo => "one", :bar => {0 => 3, 1 => 2, 2 => 1, :new => "newval"}}

    def set_path! path, val, meta=nil
      meta    ||= @data[1]
      prev_data = nil
      prev_key  = nil

      iterate_path path do |curr_data, k, i|
        if block_given?
          yield curr_data, prev_key, meta

        else
          if Array === curr_data[0] && !(Integer === k)
            curr_data[0] = curr_data[0].to_hash
          end
        end

        if !(Hash === curr_data[0]) && !(Array === curr_data[0])
          curr_data[0] = Integer === k ? Array.new(k, [nil, meta]) : Hash.new
        end

        prev_data = curr_data
        prev_key  = k

        curr_data[0][k] ||= [nil, meta] if path.length > i+1
      end

      if self.class === val && meta.nil?
        val = val.marshal
      else
        val = val.value if self.class === val
        val = self.class.assign_meta val, meta
      end

      prev_data[0][prev_key] = val
    end


    ##
    # Deletes the datapoint specified by the given path.
    # Cleans up and removes all empty data points in the given path.

    def delete_path path, meta=nil
      all_datas = []

      iterate_path path do |curr_data, k, i|
        all_datas.unshift curr_data[0]
      end

      prev_data = nil

      path.reverse.each_with_index do |k, i|
        curr_data = all_datas[i]

        if !prev_data || prev_data.empty?
          curr_data.delete_at(k) if Array === curr_data
          curr_data.delete(k)    if Hash === curr_data
        end

        prev_data = curr_data
      end
    end


    ##
    # Iterate through each data point for a given path array.

    def iterate_path path
      curr_data = @data
      prev_key  = nil

      path.each_with_index do |k, i|
        prev_key = k

        yield curr_data, k, i if block_given?

        if curr_data[0] && !(Hash === curr_data[0] || Array === curr_data[0])
          raise InvalidPathError,
            "Bad path #{path.inspect} at '#{k}' for " +
              curr_data[0].class.to_s
        end

        curr_data = curr_data[0][k]
      end

    rescue TypeError => e
      raise unless e.message =~ /can't convert String into Integer/
      raise TypeError,
        "Expected Integer in path #{path.inspect} at #{prev_key.inspect}"
    end


    ##
    # Returns a string representation of the data. Will pass the metadata for a
    # given line to a block when passed, and use the return
    # value as left columns meta.

    def stringify &columns
      rows = self.to_columns(&columns)

      cols_w = []

      rows.each do |cols|
        cols[0...-1].each_with_index do |val, i|
          cols_w[i] = val.to_s.length if cols_w[i].to_i < val.to_s.length
        end
      end

      out = ""

      rows.each do |cols|
        cols.each_with_index do |val, i|
          meth = Fixnum === val ? :rjust : :ljust
          out << val.to_s.send(meth, cols_w[i].to_i)
        end

        out << $/
      end

      out
    end


    ##
    # Returns rows and columns representing the stringified data.

    def to_columns out=[], indent=0, prefix="", &columns
      cols_w    = []
      columns ||= lambda{|meta, line_num, line| [line]}

      case @data[0]

      when Array
        if out.last === Array
          out.last.last << prefix
        elsif !prefix.empty?
          append_row out, prefix, indent, &columns
        end

        self.each do |key, doc|
          doc.to_columns(out, indent+1, "[#{key}] ", &columns)
        end

      when Hash
        if out.last === Array
          out.last.last << prefix
        elsif !prefix.empty?
          append_row out, prefix, indent, &columns
        end

        self.each do |key, doc|
          doc.to_columns(out, indent+1, "#{key}: ", &columns)
        end

      else
        append_row out, "#{prefix}#{self.value.inspect}", indent, &columns
      end

      out
    end


    ##
    # Appends a row to the columnized output.

    def append_row out, str, indent=0, &columns
      str = "#{" " * indent}#{str}"
      out << columns.call(self.metadata, out.length + 1, str).to_a
      out
    end


    ##
    # Returns the original object that metadata was assigned to.

    def value
      data_value = nil

      case @data[0]
      when Hash
        data_value = {}
        @data[0].each do |key, val|
          key = key.to_s unless Symbol === key || String === key

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
  end
end


class Array
  def to_hash
    hash = {}
    each_with_index{|v,k| hash[k] = v}
    hash
  end
end

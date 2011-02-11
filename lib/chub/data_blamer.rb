class Chub

  class DataBlamer

    ##
    # Diff the data between two revisions of data.

    def self.diff data_left, data_right
      out = {}

      flat_right = flatten_data data_right

      flatten_data data_left do |path, lvalue|
        rvalue = flat_right.delete path

        if rvalue == lvalue
          out[path] = lvalue
        else
          out[path] = [lvalue, rvalue]
        end
      end

      flat_right.each do |path, rvalue|
        out[path] = [nil, rvalue]
      end

      out
    end


    ##
    # Flattens the data structure into two dimensional path_ary => value hash.
    # If block is given, gets run when values are found;
    # passes path and value as args. If the block returns true-ish,
    # the method will continue recursively mining the data, otherwise will
    # move on to the next sibling if available.

    def self.flatten_data data, out=nil, path=nil, &block
      out  ||= {}
      path ||= []

      out[path] = data
      continue = block.call(path, data) if block_given?

      return out unless continue

      case data
      when Array
        data.each_with_index do |val, i|
          new_path = path.dup << i
          flatten_data val, out, new_path
        end
      when Hash
        data.each do |key, val|
          new_path = path.dup << key
          flatten_data val, out, new_path
        end
      end

      out
    end


    ##
    # Instantiate the blamer with any number of data revision hashes.
    #
    # Hashes must include the following key/values:
    # :author::    String - The person who made the change.
    # :timestamp:: Time   - When the change was made.
    # :data::      Object - The data to diff.
    #
    # Optionally, a :revision key may be given for informational purposes.

    def initialize *revisions
      @revisions = revisions.sort{|x, y| x[:timestamp] <=> y[:timestamp]}
    end


    ##
    # Blame the revisions stack. If last_blank is false, the last revision
    # on the stack will be entirely attributed to that revision,
    # otherwise the revision information will be blank.

    def blame last_blank=true
      
    end
  end
end

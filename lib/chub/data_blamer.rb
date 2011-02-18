class Chub

  class DataBlamer

    ##
    # Diff the data between two revisions of data.

    def self.old_diff data_left, data_right
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
    # :data::      Object - The data to diff.
    #
    # Any additional key/values will be added to the meta data.
    #
    # The revisions Array must be sorted from oldest to newest.

    def initialize *revisions
      @revisions = revisions
    end


    ##
    # Blame the revisions stack. If last_blank is false, the last revision
    # on the stack will be entirely attributed to that revision,
    # otherwise the revision information will be blank.

    def blame last_blank=true
      blamed = nil

      @revisions.each do |rev|
        blamed = compare blamed, rev.dup
      end

      blamed
    end


    ##
    # Compare two data objects and return a MetaNode.

    def compare data_left, data_right
      recursive_compare MetaNode.build(data_left.delete(:data), data_left),
                        MetaNode.build(data_right.delete(:data), data_right)
    end


    def recursive_compare data_left, data_right
      return data_left  if data_left == data_right
      return data_right if data_left.class != data_right.class

      case data_left
      when Hash, MetaHash
        compare_hashes data_left, data_right

      when Array, MetaArray
        compare_arrays data_left, data_right

      else
        data_right
      end
    end


    ##
    # Compare and merge two hashes.

    def compare_hashes data_left, data_right
      output = MetaNode.build(Hash.new, data_right.meta)

      data_left.each do |lkey, lvalue|
        puts "MATCHING #{lkey}"
        # Same value, use data_left
        if data_right[lkey] == data_left[lkey]
          output[lkey] = lvalue
          data_right.delete lkey
          data_left.delete lkey
          next
        end

        # Check if key was deleted, or value was moved
        data_right.each do |rkey, rvalue|

          if rvalue == lvalue && data_left[rkey] != rvalue
            output[rkey] = data_left[lkey]
            data_right.delete rkey
            puts "found #{rkey}"

          elsif !data_left.has_key?(rkey)
            key, val = data_left.find{|k, v| v == rvalue}

            if key
              puts "setting #{rkey} from left"
              output[rkey] = data_left.delete key
              data_right.delete rkey
            else
              puts "setting #{rkey} from right"
              output[rkey] = data_right.delete rkey
            end
          end
        end

        # Check if value was changed
        if data_right.has_key? lkey
          output[lkey] = recursive_compare lvalue, data_right.delete(lkey)
          puts "submatched #{lkey} -> #{output[lkey]}"
        end

        data_left.delete lkey
      end

      output
    end


    ##
    # Compare and merge two arrays.

    def compare_arrays data_left, data_right
      output = MetaNode.build(Array.new, data_right.meta)
      i = -1

      until data_right.empty?
        i = i.next

        if data_right.first == data_left[i]
          data_right.shift
          output << data_left[i]
          next
        end

        ri = data_right.index data_left[i] if data_left.length >= i + 1
        li = data_left.index data_right[0]

        if ri # item was found further down the right array, pull range
          index = ri - 1
          output.concat data_right.slice!(0..index)

          data_right.shift
          output << data_left[i]

        elsif li && li > i # item was found further down the left array, skip
          i = li - 1
          next

        else
          output << recursive_compare(data_left[i], data_right.shift)
        end
      end

      output
    end


    ##
    # Creates a String representation from data.

    def data_to_string data, indent=0
      case data

      when Hash
        output = "{\n"

        data_values =
          data.map do |key, value|
            pad = " " * indent
            subdata = ordered_data_string value, indent + 1
            "#{pad}#{key.inspect} => #{subdata}"
          end

        output << data_values.join(",\n") << "\n" unless data_values.empty?
        output << "#{" " * indent}}"

      when Array
        output = "[\n"

        data_values =
          data.map do |value|
            pad = " " * indent
            "#{pad}#{ordered_data_string value, indent + 1}"
          end

        output << data_values.join(",\n") << "\n" unless data_values.empty?
        output << "#{" " * indent}]"

      else
        data.inspect
      end
    end
  end
end

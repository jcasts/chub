class Chub

  class DataBlamer


    ##
    # Diff the data between two revisions of data.

    def self.diff data_left, data_right
      flat_left  = flatten_data data_left
      flat_right = flatten_data data_right

      # DIFF IT!
    end


    ##
    # Flattens the data structure into two dimensional [path_ary, value] array.

    def self.flatten_data data, out=nil, path=nil
      out  ||= []
      path ||= []

      out << [path, data]

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

    def blame last_blank=false
      
    end
  end
end

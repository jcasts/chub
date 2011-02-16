class Chub

  ##
  # Blames according to revisions and associated metadata.

  class Blamer

    ##
    # Create a new blame from an array of data revisions.
    # Each revision must be a hash containing a data key with the data
    # to blame, and a meta key with the blame data.

    def self.new_from_data *data_revs
      data_revs.map! do |rev|
        {:meta => rev[:meta], :data => Diff.ordered_data_string(rev[:data])}
      end

      new(*data_revs)
    end


    ##
    # Create a new blamer with string history and revision metadata.
    # Each revision must be a hash containing a data key with the string
    # to blame, and a meta key with the blame data.
    #
    # Revisions should be in order from newest to oldest.

    def initialize *revs
      @revisions = revs
    end


    ##
    # Creates a blamed data string and returns a two dimensional Array
    # with blame/line pairs.

    def create_blame last_blank=true
      blame = [@revisions.first[:meta]] * @revisions.first[:data].lines.count

      @revisions[1..-1].each_with_index do |rev, i|
        line = 0

        rev_meta = rev[:meta]
        rev_meta = nil if last_blank && @revisions.length = i+2

        differ = Diff.new @revisions.first[:data], rev[:data]

        differ.create_diff do |diff|
          if String === diff
            blame[line] = rev_meta
            line = line.next

          elsif !diff[0].empty?
            line = line + diff[0].length
          end
        end
      end

      blame.zip @revisions.first[:data]
    end
  end
end

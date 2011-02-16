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

    def initialize *revs
      @revisions = revs
    end


    ##
    # Create the blamed data string.

    def create_blame
    end
  end
end

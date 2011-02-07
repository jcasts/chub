module Couch

  ##
  # Class to interact with a document database.

  class DB < Resource

    ##
    # Instantiate a new DB object with its name and server.

    def initialize name, server
      @name      = name
      @data      = nil
      @documents = nil

      super "/#{@name}", server
    end


    ##
    # Returns an array of documents belonging to this DB.

    def documents force=false
      return @documents if @documents && !force

      all_docs_path = File.join @path, "_all_docs"

      @documents = @server.get(all_docs_path)["rows"].map do |doc|
        Document.new self, doc["id"]
      end
    end
  end
end

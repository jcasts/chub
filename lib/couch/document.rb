module Couch

  ##
  # Represents a document for a given db.

  class Document < Resource

    ##
    # Instantiate a new Document for the given DB instance.

    def initalize db, id
      @db   = db
      @name = id

      super File.join(@db.path, @name), @db.server
    end
  end
end

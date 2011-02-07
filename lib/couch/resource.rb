module Couch

  ##
  # Base class for any Couch resource (DB, Document).

  class Resource

    # Path on server to the resource.
    attr_reader :path

    # Server instance to query resource from.
    attr_reader :server


    ##
    # Initialize a new resouce for the given path.

    def initialize path, server
      @path   = path
      @server = server
    end


    ##
    # Create a new resource. Returns Resource#data if created, false if the
    # resource already exists.

    def create data
      create! data
    rescue Server::ConflictError
      false
    end


    ##
    # Same as Resource#create but raises errors on failure.

    def create! data
      @server.put(@path, data)
      self.data true
    end


    ##
    # Returns the cached resource data. If data is nil, or the force argument
    # is true, calls Resource#read.

    def data force=false
      @data = read if @data.nil? || force
      @data
    end


    ##
    # Delete a new resource. Returns true if deleted, false if the
    # resource doesn't exists.

    def delete
      delete!
    rescue Server::NotFoundError
      false
    end


    ##
    # Same as Resource#delete but raises errors on failure.

    def delete!
      !!@server.delete(@path)
    end


    ##
    # Check if the resource exists on the server.

    def exist?
      !!@server.get(@path)
    rescue Server::NotFoundError
      false
    end


    ##
    # Update the resource by merging in the new data.
    # Returns Resource#data if updated, false if the resource didn't update.

    def update data
      udpate! data
    rescue Server::ConflictError
      false
    end


    ##
    # Same as Resource#update but raises errors on failure.

    def udpate! data
      data = (self.data || Hash.new).merge data
      @server.put(@path, data)
      self.data true
    end


    ##
    # Reads the resource data. Returns nil if resource is missing.
    # Updates the @data attribute on success.

    def read
      read!
    rescue Server::NotFoundError
    end


    ##
    # Same as Resource#read but raises errors on failure.

    def read!
      @data = @server.get @path
    end
  end
end

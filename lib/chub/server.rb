class Chub

  ##
  # Backend Chub server to get configs from.

  class Server

    ##
    # Instantiate new Chub server instance.

    def initialize host, port=nil
      @couchdb = Couch::Server.new host, port
    end
  end
end

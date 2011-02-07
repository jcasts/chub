module Couch

  ##
  # Base class for interacting with the CouchDB server.

  class Server

    # Base server error class.
    class Error < ::Exception; end

    # The request made was invalid.
    class BadRequestError < Error; end

    # The request made was invalid.
    class NotFoundError < Error; end

    # The specified resource already exists.
    class ConflictError < Error; end


    ##
    # Create a new server instance.

    def initialize host, port = 5984
      @host    = host
      @port    = port
    end


    ##
    # Delete a document.

    def delete uri
      request(Net::HTTP::Delete.new(uri))
    end


    ##
    # Read a document.

    def get uri
      request(Net::HTTP::Get.new(uri))
    end


    ##
    # Create or update a document.

    def put uri, data
      req = Net::HTTP::Put.new(uri)
      req["content-type"] = "application/json"
      req.body = data.to_json
      request(req)
    end


    ##
    # Create a new document.

    def post uri, data
      req = Net::HTTP::Post.new(uri)
      req["content-type"] = "application/json"
      req.body = data.to_json
      request(req)
    end


    ##
    # Base method for making a request.

    def request req
      res = Net::HTTP.start(@host, @port) { |http|http.request(req) }
      unless res.kind_of?(Net::HTTPSuccess)
        handle_error(req, res)
      end

      JSON.parse res.body
    end


    private

    ##
    # Raise error when response code >= 400

    def handle_error req, res
      message = "#{res.code}:#{res.message}\n" +
                "METHOD:#{req.method}\nURI:#{req.path}\n#{res.body}"

      case res.code
      when 400 then raise BadRequestError, message
      when 404 then raise NotFoundError,   message
      when 409 then raise ConflictError,   message
      else
        raise Error, message
      end
    end
  end
end


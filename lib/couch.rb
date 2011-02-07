require 'net/http'
require 'json'

##
# A simple REST method wrapper around CouchDB calls.

module Couch
  require 'couch/server'
  require 'couch/resouce'
  require 'couch/db'
  require 'couch/document'
end

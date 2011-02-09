class Chub

  class AppConfig
    include Mongoid::Document

    attr_writer :previous

    field :name
    field :data, :type => Hash
    field :rev,  :uniq => true
    field :prev_rev

    #references_one  :previous, :class_name => "Chub::AppConfig" #self.name
    #references_many :includes, :class_name => self.name

    field :updated_by, :default => Chub.config['user']
    field :updated_at, :default => Time.now, :type => Time

    before_create :assign_previous
    before_create :assign_rev
    before_update :set_time_and_user

    validates_presence_of :name, :updated_by, :updated_at


    ##
    # Return the specified app_config document with recursively added includes.

    def self.read name
      app_config = latest(name)
      app_config && app_config.document
    end


    ##
    # Returns the latest AppConfig instance with the given name.

    def self.latest name
      self.last :conditions => {:name => name}
    end


    ##
    # Create a new revision of the document.

    def self.create_rev name, new_data={}
      app_config = latest(name)

      if app_config
        app_config.create_rev new_data
      else
        self.create :name => name, :data => new_data
      end
    end


    ##
    # Creates and saves a new revision as a child of the current one.

    def create_rev new_data={}
      new_data   = self.data.merge(new_data)
      app_config = self.class.new :name     => self.name,
                                  :data     => new_data
                                  #:includes => self.includes

      app_config.previous = self
      app_config.save
      app_config
    end


    ##
    # Get the previous revision of this app_config.

    def previous
      @previous ||= self.class.last :conditions => {:rev => self.prev_rev}
    end


    ##
    # Returns the fully merged config document with recursively added includes.

    def document
      return self.data if self.includes.empty?

      doc = self.data.dup || Hash.new

      self.includes.each do |incl|
        doc = incl.document.merge doc
      end

      doc
    end


    ##
    # Returns a blamed string output.
    # Passing history an integer will limit the number of revisions.

    def blame history=nil
      count = history || :all
      confs = self.class.find count, :conditions => {:name => self.name}
    end


    protected


    def assign_rev
      self.rev ||= UUID.generate
    end


    def assign_previous
      prev = self.previous || self.class.latest(name)
      self.prev_rev = prev.rev if prev
    end


    def set_time_and_user
      self.updated_by = Chub.config['user']
      self.updated_at = Time.now
    end
  end
end

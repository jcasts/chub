class Chub

  class AppConfig
    include Mongoid::Document

    attr_writer :previous

    field :name
    field :data, :type => Hash
    field :rev,  :uniq => true
    field :prev_rev

    field :updated_by, :default => Chub.config['user']
    field :updated_at, :default => Time.now,  :type => Time
    field :includes,   :default => Array.new, :type => Array
    field :active,     :default => true,      :type => Boolean

    before_create :assign_previous
    before_validation :assign_rev
    before_update :set_time_and_user

    validates_presence_of :name, :rev, :updated_by, :updated_at

    scope :active, :where => { :active => true }

    attr_accessible :name, :data, :updated_by, :includes


    ##
    # Return the specified app_config document with recursively added includes.

    def self.read name
      app_config = current(name)
      app_config && app_config.document
    end


    ##
    # Returns the latest AppConfig instance with the given name.

    def self.latest name
      self.last :conditions => {:name => name}
    end


    ##
    # Returns the currently active AppConfig with the given name.

    def self.current name
      self.active.where(:name => name).first
    end


    ##
    # Create a new revision of the document
    # based on the currently active AppConfig.

    def self.create_rev name, new_data={}
      app_config = current(name)

      if app_config
        app_config.create_rev new_data
      else
        self.create :name => name, :data => new_data
      end
    end


    ##
    # Creates and saves a new revision as a child of this instance.

    def create_rev new_data={}
      new_data   = self.data.merge(new_data)
      app_config = self.class.new :name     => self.name,
                                  :data     => new_data,
                                  :includes => self.includes

      app_config.previous = self
      app_config.save!

      self.active = false
      self.save!

      app_config
    end


    ##
    # Get the previous revision of this app_config.

    def previous
      @previous ||= self.class.last :conditions => {:rev => self.prev_rev}
    end


    ##
    # Add an app_config as included in this one
    # and puts it at the top of the stack.

    def include app_config
      self.includes.unshift app_config.name
    end


    ##
    # Check if an app_config or app_config name is already included.

    def include? app_config
      conf_name = self.class === app_config ? app_config.name : app_config
      self.includes.include? conf_name
    end


    ##
    # Returns the fully merged config document with recursively added includes.

    def document
      return self.data if self.includes.empty?

      doc = self.data.dup || Hash.new

      doc_includes = self.class.active.any_in :name => self.includes

      doc_includes.each do |incl|
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

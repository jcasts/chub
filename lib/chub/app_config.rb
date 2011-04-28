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
    # If a revision (or its first few characters) is given, will return
    # the latest app_config with that matches it.

    def self.latest name, rev=nil
      conditions = {:name => name}
      conditions[:rev] =  /^#{rev}/ if rev
      self.where(conditions).order_by(:updated_at.asc).limit(1).first
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
    # Options supported are :timestamp and :user.

    def create_rev new_data={}, options={}
      options[:timestamp] ||= Time.now
      options[:user]      ||= Chub.config['user']
      options[:file]        = self.name

      new_doc = Document.new new_data, options.dup
      new_doc = self.document.merge new_doc

      app_config =
        self.class.new :name       => self.name,
                       :data       => new_doc.value,
                       :includes   => self.includes,
                       :updated_at => options[:timestamp],
                       :updated_by => options[:user]

      app_config.previous = self

      app_config.data[1][:revision]  = app_config.assign_rev

      app_config.save!

      self.active = false
      self.save!

      app_config
    end


    ##
    # Returns true if this instance is the currently used revision.

    def current?
      self.rev == self.class.current(self.name).rev
    end


    ##
    # Returns true if this instance is the most recent revision.

    def latest?
      self.rev == self.class.latest(self.name).rev
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
      return @document if @document && self.current?

      doc = Document.new_from data

      return doc if self.includes.empty?

      doc_includes = self.class.active.any_in :name => self.includes

      doc_includes.each do |incl|
        doc = incl.document.merge doc
      end

      @document = doc
    end


    ##
    # Returns a blamed string output.
    # Passing history an integer will limit the number of revisions.

    def blame
      self.document.stringify do |meta, line_num, line|
        [
          meta[:file],
          meta[:revision].split("-").first,
          "(#{meta[:user]}",
          meta[:timestamp].strftime("%Y-%m-%d %H:%M:%S %z"),
          "#{line_num})",
          line
        ]
      end
    end


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

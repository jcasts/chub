class Chub

  class AppConfig
    include Mongoid::Document

    attr_writer :previous

    field :name
    field :data, :type => Array
    field :rev,  :uniq => true
    field :prev_rev

    field :updated_by, :default => Chub.config['user']
    field :created_at, :default => Time.now,  :type => Time
    field :updated_at, :default => Time.now,  :type => Time
    field :includes,   :default => Array.new, :type => Array
    field :active,     :default => false,     :type => Boolean

    before_validation :assign_rev
    before_create :assign_previous
    before_update :set_time_and_user

    after_save :ensure_active
    before_destroy :ensure_active

    validates_presence_of :name, :rev, :updated_by, :updated_at, :created_at

    scope :active, :where => { :active => true }

    attr_accessible :active, :name, :data, :updated_by,
                    :includes, :rev, :created_at


    ##
    # Return the specified app_config document value
    # with recursively added includes.

    def self.read name
      app_config = current(name)
      app_config && app_config.document && app_config.full_document.value
    end


    ##
    # Returns the latest AppConfig instance with the given name.
    # If a revision (or its first few characters) is given, will return
    # the latest app_config with that matches it.

    def self.latest name
      conditions = {:name => name}
      self.where(conditions).order_by(:created_at.desc).limit(1).first
    end


    ##
    # Returns the currently active AppConfig with the given name.

    def self.current name
      self.active.where(:name => name).order_by(:created_at.desc).first
    end


    ##
    # Returns the AppConfig instance with the given name and revision.

    def self.revision name, rev
      conditions = {:name => name, :rev => /^#{rev}/}
      self.where(conditions).first
    end


    ##
    # Create a new revision of the document
    # based on the currently active AppConfig, the revision specified in
    # the options with :from_rev, or an actual AppConfig instance given
    # to the :from option.
    # Options supported are :from_rev, :from, 'timestamp' and 'user'.

    def self.new_rev name, options={}
      options     = options.dup
      prev_config = options.delete :from
      from_rev    = options.delete :from_rev

      prev_config ||=
        from_rev ? revision(name, from_rev) : current(name)

      options['timestamp'] ||= Time.now
      options['user']      ||= Chub.config['user']
      options['file']        = name
      options['revision']    = UUID.generate

      new_doc = Document.new Hash.new, options

      app_config =
        self.new :name       => options['file'],
                 :created_at => options['timestamp'],
                 :updated_by => options['user'],
                 :rev        => options['revision'],
                 :active     => true

      if prev_config
        new_doc = prev_config.document.dup if prev_config.document
        app_config.previous = prev_config
        app_config.includes = prev_config.includes.dup
      end

      app_config.data = new_doc.data
      app_config
    end


    ##
    # Creates a new revision as a child of this instance in memory.
    # Options supported are 'timestamp' and 'user'.

    def new_rev options={}
      self.class.new_rev self.name, options.merge(:from => self)
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

    def full_document
      doc = self.document
      return unless doc
      return doc if self.includes.empty?

      doc_includes = self.class.active.any_in :name => self.includes

      doc_includes.each do |incl|
        doc = incl.full_document.merge doc
      end

      doc
    end


    ##
    # Returns the config document without includes.

    def document
      return unless self.data
      Document.new_from self.data
    end


    ##
    # Returns the most up-to-date metadata to use in the document.

    def curr_meta
      {
        'timestamp' => self.created_at,
        'user'      => Chub.config['user'],
        'file'      => self.name,
        'revision'  => self.rev
      }
    end


    ##
    # Sets data at the given String path. Accepts optional metadata as a Hash
    # to merge.
    #   app_config.set_path "path/to/prop", "value", "user" => "joe"

    def set_path path, val, meta={}
      meta = self.curr_meta.merge meta
      path = path.split("/").map{|p| p =~ /^\d+$/ ? p.to_i : p}
      self.document.set_path path, val, meta
    end


    ##
    # Returns a blamed string output.
    # Passing history an integer will limit the number of revisions.

    def blame
      "[#{self.name} #{self.rev.split("-").first}]\n\n" +
      self.full_document.stringify do |meta, line_num, line|
        [
          meta['file'], " ",
          meta['revision'].split("-").first, " ",
          "(#{meta['user']}", " ",
          meta['timestamp'].strftime("%Y-%m-%d %H:%M:%S %z"), " ",
          "#{line_num})",
          line
        ]
      end
    end


    ##
    # Ensures there is a unique active config per name.

    def ensure_active
      active_configs = self.class.active.where(:name => self.name).
                        order_by(:created_at.desc)

      if active_configs.empty?
        if self.previous
          self.previous.active = true
          self.previous.save!
        else
          latest_config = self.class.latest self.name
          return unless latest_config

          latest_config.active = true
          latest_config.save!
        end

      elsif active_configs.length > 1
        active_configs[1..-1].each do |ac|
          ac.active = false
          ac.save!
        end
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

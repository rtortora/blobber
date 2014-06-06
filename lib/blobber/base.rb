module Blobber
  class Base
    attr_accessor :blob
    attr_accessor :warnings
    include ::Blobber::Attrs

    public
    def initialize(data = {}, &block)
      self.warnings = []
      apply_blob(data)
      if block_given?
        yield(self)
      end
    end

    public
    def apply_blob(data)
      cached_views = get_blob_views
      data.each do |key, val|
        next if key == "warnings" || cached_views[key]
        if get_blob_attr_def(key)
          constructed = construct_blob_val(key, val)
          send("#{key}=", constructed)
        else
          do_warn = true
          if self.class.respond_to?("blob_properties_never_read") &&
              self.class.blob_properties_never_read.include?(key.to_s)
            do_warn = false
          end
          if do_warn
            warnings << "Skipped data key '#{key}' - no such attrib"
          end
        end
      end
    end

    public
    def self.parse_blob(blob)
      return self.send("new", blob)
    end

    public
    def self.parse(str)
      return parse_blob(JSON::parse(str))
    end

    public
    def as_json(*args)
      flush
      json = JSON::parse(blob)
      if warnings && warnings.size > 0
        json[:warnings] = warnings
      end
      return json
    end

    public
    def to_json(*args)
      # HACK TODO this is really dumb, since blob is already a string, but it's
      # also dumb if a subclass wants to override the json behavior - it should
      # only need to override as_json. Example of this is MechanicCommands::Base.
      return as_json.to_json
      # flush
      # return blob
    end
  end
end

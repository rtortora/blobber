module Blobber
  class Base
    attr_accessor :blob
    include ::Blobber::Attrs

    public
    def initialize(data = {}, opt = {}, &block)
      apply_blob(data, opt)
      if block_given?
        yield(self)
      end
    end

    public
    def apply_blob(data, opt = {})
      opt[:ignore_missing] = true unless opt.key?(:ignore_missing)
      data.each do |key, val|
        if get_blob_attr_def(key)
          constructed = construct_blob_val(key, val)
          send("#{key}=", constructed)
        else
          raise "No such data key '#{key}'" unless opt[:ignore_missing]
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

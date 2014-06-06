module Blobber
  module Attrs
    public
    def self.included(base)
      base.extend(ClassMethods)
    end

    public
    def reset
      @blob_values = {}
      @blob_views = {}
    end

    private
    def get_blob_views
      view_holders = []
      klass = self.class
      while (klass != nil)
        view_holders << klass.instance_variable_get("@blob_views")
        klass = klass.superclass
      end
      views = {}
      view_holders.compact.reverse.each do |view_holder|
        views.merge!(view_holder)
      end
      return views
    end

    private
    def get_blob_attr_defs
      attr_holders = []
      klass = self.class
      while (klass != nil)
        attr_holders << klass.instance_variable_get("@blob_attrs")
        klass = klass.superclass
      end
      attrs = {}
      attr_holders.compact.reverse.each do |attr_holder|
        attrs.merge!(attr_holder)
      end
      return attrs
    end

    public
    def get_blob_view(key)
      return get_blob_views[key.to_s]
    end

    public
    def get_blob_attr_def(key)
      return get_blob_attr_defs[key.to_s]
    end

    private
    def get_blob_attr_def!(key)
      dfn = get_blob_attr_defs[key.to_s]
      raise "No definition for blob attr '#{key}'" unless dfn
      return dfn
    end

    public
    def get_blob_val(key)
      @blob_values ||= {}
      if @blob_values[key.to_s].nil?
        if blob.nil?
          source = {}
        else
          source = JSON.parse(blob)
        end
        if source[key.to_s].nil?
          set_blob_val(key, default_blob_val(key))
        else
          set_blob_val(key, construct_blob_val(key, source[key.to_s]))
        end
      end
      return @blob_values[key.to_s]
    end

    public
    def set_blob_val(key, val)
      validate_proposed_blob_val!(key, val)
      if blob.nil?
        source = {}
      else
        source = JSON.parse(blob)
      end
      @blob_values ||= {}
      @blob_values[key.to_s] = val
      source[key.to_s] = val
      self.blob = source.to_json
    end

    public
    def flush
      @blob_values ||= {}
      if blob.nil?
        source = {}
      else
        source = JSON.parse(blob)
      end
      get_blob_views.each do |key, callback|
        source[key.to_s] = instance_exec(self, &callback)
      end
      get_blob_attr_defs.each do |key, info|
        if @blob_values[key.to_s].nil?
          set_blob_val(key, default_blob_val(key))
        end
        source[key.to_s] = @blob_values[key]
      end
      self.blob = source.to_json
    end

    private
    def default_blob_val(key)
      dfn = get_blob_attr_def!(key)
      if dfn.key?("default")
        if dfn[:default].class == Proc
          return normalize_blob_val(key, instance_exec(&dfn[:default]))
        else
          return normalize_blob_val(key, dfn[:default])
        end
      elsif dfn[:array]
        return []
      elsif dfn[:hash]
        return {}
      elsif dfn[:class]
        klass = dfn[:class]
        if klass.class == Proc
          klass = klass.call()
        end
        return normalize_blob_val(key, klass.new)
      else
        return nil
      end
    end

    private
    def construct_blob_val(key, raw)
      dfn = get_blob_attr_def!(key)
      if raw.nil?
        return nil
      elsif dfn[:array]
        values = []
        raw.each do |item|
          if dfn[:class]
            values << normalize_blob_val(key, construct_blob_val_as_class(item, dfn[:class]))
          else
            values << normalize_blob_val(key, item)
          end
        end
        return values
      elsif dfn[:hash]
        values = {}
        raw.each do |rkey, val|
          if dfn[:class]
            values[rkey.to_s] = normalize_blob_val(key,
                                                   construct_blob_val_as_class(val, dfn[:class]))
          else
            values[rkey.to_s] = normalize_blob_val(key, val)
          end
        end
        return values
      else
        if dfn[:class]
          return normalize_blob_val(key,
                                    construct_blob_val_as_class(raw, dfn[:class]))
        else
          return normalize_blob_val(key, raw)
        end
      end
    end

    private
    def construct_blob_val_as_class(raw, klass)
      if klass.class == Proc
        klass = klass.call(raw)
      end
      if klass.respond_to?("parse_blob")
        return klass.parse_blob(raw)
      else
        return klass.new(raw)
      end
    end

    private
    def normalize_blob_val(key, val)
      dfn = get_blob_attr_def!(key)
      if dfn[:callback]
        instance_exec(val, &dfn[:callback])
      end
      return val
    end

    private
    def validate_proposed_blob_val!(key, val)
      dfn = get_blob_attr_def!(key)
      if val.nil?
        if dfn[:allow_nil] == false
          raise "Cannot set blob key '#{key}' to null"
        end
      else    
        if dfn[:array]
          if val.class != Array
            raise "Cannot convert #{val.class} to Array"
          end
          if dfn[:class] && dfn[:class].class != Proc
            invalid_classes = val.map{|x| x.class}.uniq.reject{|x| x == dfn[:class]}
            if invalid_classes.any?
              raise "Cannot convert classes [" + invalid_classes.map{|x| x.name}.join(', ') + "] to [#{dfn[:class]}]"
            end
          end
        elsif dfn[:hash]
          if val.class != Hash
            raise "Cannot convert #{val.class} to Hash"
          end
          if dfn[:class]
            invalid_classes = val.values.map{|x| x.class}.uniq.reject{|x| x == dfn[:class]}
            if invalid_classes.any?
              raise "Cannot convert classes [" + invalid_classes.map{|x| x.name}.join(', ') + "] to [#{dfn[:class]}]"
            end
          end
        else
          if dfn[:class]
            if val.class != dfn[:class]
              raise "Cannot convert class #{val.class} to #{dfn[:class]}"
            end
          end
        end
      end
    end

    public
    module ClassMethods
      def blob_view(key, &block)
        @blob_views ||= {}
        @blob_views[key.to_s] = block
        define_method key do
          instance_exec(self, &block)
        end
      end

      def blob_attr(key, opt = {})
        @blob_attrs ||= {}
        if @blob_attrs.count == 0
          # need to flush before saving in case an array changed or some child
          # property, etc
          if respond_to?(:before_save)
            before_save do |record|
              record.flush
            end
          end
        end

        @blob_attrs[key.to_s] = Hashie::Mash.new(opt)

        define_method key do
          get_blob_val(key)
        end

        define_method "#{key}=" do |val|
          set_blob_val(key, val)
        end
      end
    end
  end
end

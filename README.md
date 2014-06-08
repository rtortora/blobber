blobber
=======

A light-weight DSL for accessing attributes stored in a JSON blob.

## Usage

Here's an example:

    class Point < Blobber::Base
      blob_attr :x, default: 0
      blob_attr :y, default: 0
    end
    
Now you can use attributes `x` and `y` like you might a normal attribute, but it's backed by a JSON blob that can be easily serialized.

    saved = Point.new(x: 1, y: 2)
    saved.as_json
    => {
          "x" => 1
          "y" => 2
       }
       
    loaded = Point.new(saved)
    loaded.as_json
    => {
          "x" => 1
          "y" => 2
       }

       
Now let's try something a bit more complex:

    class Shape < Blobber::Base
      blob_attr :type, read_only: ->() { "shape" }
      blob_attr :points, container: :array, class: Point, default: ->() { [] }
    end
    
    example = Shape.new(points: [{x: 1, y: 2}, {x: 4, y: 6}])
    
    example.as_json
    => {
         "type" => "shape",
         "points" => [
                        { "x": 1, "y": 2 },
                        { "x": 4, "y": 6 }
                     ]
        }
        
    example.points.first.class
    => Point
    
## Combining with Active Record
It can be really convenient to store a bunch of configuration objects inside a single JSON-blob value. By adding in Blobber, you can still have nicely constructured objects.

    class ShapeSystem < ActiveRecord::Base
      include Blobber::Attrs
      blob_attr :shapes, container: :array, class: Shape
    end

When including `Blobber::Attrs` it presumes the object has a property called `blob`. So make sure to add such a column on your object.

## Blob Attribute Options
### class
Specifies the class of the attribute; or if using an array container, then the class of the value; if using a hash container, then the class of the value (key always assumed to be strings).

If the class has a `parse_blob` method, it prefers to use that to construct the object from a JSON blob. The `Blobber::Base` defines this - generally you shouldn't need to yourself. Failing that, it will just call `new` and pass in the JSON blob.

You can provide a callback for the class which will be executed each time it goes to construct, passing the raw JSON value when it does. This is used for implementing dynamic subclass loading.

    class BaseObj < Blobber::Base
      blob_attr :items, container: :array, class: ->(raw) {
        if raw["type"] == 'Apple'
          return Apple
        elsif raw['type'] == 'Orange'
          return Orange
        end
      }
    end
    
    class Apple < Blobber::Base
      blob_attr :type, read_only: ->() { 'Apple' }
    end
    
    class Orange < Blobber::Base
      blob_attr :Type, read_only: ->() { 'Orange' }
    end
    
### container
Specifies that the blob attribute is a container. Supports `:array` or `:hash`.

When the `:hash` container type is used, any `class` specified is presumed to be the class of the value. The class of the keys is always presumed to be a string.

### default
Specifies a default value or callback when the backing JSON is missing the key.

### allow_nil
When set to false, raises an exception if anyone tries to set the value to `nil`.

### callback
When a `Proc` is specified as a `callback` option, the callback is always executed whenever the value has changed.

This can be useful to automatically tell child objects about the parent:
    
    class Parent < Blobber::Base
      blob_attr :children, container: :array, class: Child, callback: ->(obj) {
        obj.parent = self
      }
    end
    
    class Child < Blobber::Base
      attr_accessor :parent
    end
    
### read_only
Specifies that the attribute is read-only. Must provide a `Proc`, which will be called each and every time someone tries to access the variable. Attempts to explicitly set the value will raise an exception, but if a value is provided in a JSON blob that the object parses it will be totally ignored.

## A Note about Nested Objects
Note that when you nest objects (like in the above example, with `Shape` and `ShapeSystem`) a call to `flush` is needed to serialize changes in nested children back down to a JSON blob. This generally happens automatically when you call `as_json`, `to_json`. When combined with `ActiveRecord` the `Blobber::Attrs` automatically adds a `before_save` filter to call `flush`.



blobobj
=======

A light-weight DSL for accessing attributes stored in a JSON blob.

Usage
-----

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
    
Combining with Active Record
----------------------------
It can be really convenient to store a bunch of configuration objects inside a single JSON-blob value. By adding in Blobber, you can still have nicely constructured objects.

    class ShapeSystem < ActiveRecord::Base
      include Blobber::Attrs
      blob_attr :shapes, container: :array, class: Shape
    end

When including `Blobber::Attrs` it presumes the object has a property called `blob`. So make sure to add such a column on your object.

A Note about Nested Objects
--------------
Note that when you nest objects (like in the above example, with `Shape` and `ShapeSystem`) a call to `flush` is needed to serialize changes in nested children back down to a JSON blob. This generally happens automatically when you call `as_json`, `to_json`. When combined with `ActiveRecord` the `Blobber::Attrs` automatically adds a `before_save` filter to call `flush`.



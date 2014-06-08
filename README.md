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

    Point.new(x: 1, y: 2).as_json
    => {
          "x" => 1
          "y" => 2
       }
       
Now let's try something a bit more complex

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
    

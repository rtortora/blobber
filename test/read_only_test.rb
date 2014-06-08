require 'minitest/autorun'
require_relative '../lib/blobber.rb'

class ReadOnlyTest < Minitest::Test

  class MockObj < Blobber::Base
    blob_attr :name
    blob_attr :type, read_only: ->() {
      "immutable"
    }
  end

  def test_read_only
    item = MockObj.new(name: "item")
    assert_equal item.name, "item"
    assert_equal item.type, "immutable"
    assert_equal item.as_json, {
      "name" => "item",
      "type" => "immutable"
    }

    copy = MockObj.new(item.as_json.dup)
    assert_equal copy.name, "item"
    assert_equal copy.type, "immutable"
    assert_equal copy.as_json, {
      "name" => "item",
      "type" => "immutable"
    }

    mucked_json = item.as_json.dup
    mucked_json[:type] = "this shouldn't be read"
    mucked = MockObj.new(mucked_json)
    assert_equal mucked.name, "item"
    assert_equal mucked.type, "immutable"
    assert_equal mucked.as_json, {
      "name" => "item",
      "type" => "immutable"
    }
  end
end

require 'minitest/autorun'
require_relative '../lib/blobber.rb'

class ArrayTest < Minitest::Test

  class MockItem < Blobber::Base
    blob_attr :name
    blob_attr :value, default: 0
  end

  class MockContainer < Blobber::Base
    blob_attr :items, container: :array, class: MockItem
  end

  def test_array_container
    container = MockContainer.new
    container.items << MockItem.new(name: "a", value: 2)
    container.items << MockItem.new(name: "b", value: 5)
    assert_equal container.items.size, 2

    saved = container.as_json.dup
    loaded = MockContainer.new(saved)
    assert_equal loaded.items.size, 2
    assert_equal loaded.items[0].name, "a"
    assert_equal loaded.items[0].value, 2
    assert_equal loaded.items[1].name, "b"
    assert_equal loaded.items[1].value, 5
  end
end

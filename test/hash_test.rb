require 'minitest/autorun'
require_relative '../lib/blobber.rb'

class HashTest < Minitest::Test

  class MockItem < Blobber::Base
    blob_attr :name
    blob_attr :value, default: 0
  end

  class MockContainer < Blobber::Base
    blob_attr :hash, container: :hash, class: MockItem
  end

  def test_hash_container
    container = MockContainer.new
    container.hash["a"] = MockItem.new(name: "a", value: 2)
    container.hash["b"] = MockItem.new(name: "b", value: 5)
    assert_equal container.hash.size, 2

    saved = container.as_json.dup
    loaded = MockContainer.new(saved)
    assert_equal loaded.hash.size, 2
    refute_nil loaded.hash["a"]
    assert_equal loaded.hash["a"].name, "a"
    assert_equal loaded.hash["a"].value, 2
    refute_nil loaded.hash["b"]
    assert_equal loaded.hash["b"].name, "b"
    assert_equal loaded.hash["b"].value, 5
  end
end

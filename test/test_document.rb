require 'test_helper'

class TestDocument < Test::Unit::TestCase

  def setup
    @metadata = {:user => "bob"}

    @data = {
      :foo => 'bar',
      :arr => %w{a b c},
      :hsh => {
        :sub => {
          'a' => 1,
          'b' => %w{test thing}
        }
      }
    }

    @marshalled = [{
      :foo => ['bar', @metadata],
      :arr => [[['a', @metadata],
                ['b', @metadata],
                ['c', @metadata]], @metadata],
      :hsh => [{
        :sub => [{
          'a' => [1, @metadata],
          'b' => [[['test', @metadata], ['thing', @metadata]], @metadata]
        }, @metadata]
      }, @metadata]
    },
      @metadata
    ]

    @meta = Chub::Document.new_from @marshalled
  end


  def test_new_from
    meta = Chub::Document.new_from @marshalled
    assert_equal @marshalled, meta.data
  end


  def test_new
    meta = Chub::Document.new @data, @metadata
    assert_equal @marshalled, meta.data
  end


  def test_marshal
    meta = Chub::Document.new @data, @metadata
    assert_equal @marshalled, meta.marshal
  end


  def test_metadata
    meta = Chub::Document.new @data, @metadata
    assert_equal @metadata, meta.metadata
  end


  def test_assign_meta
    meta = Chub::Document.assign_meta @data, @metadata
    assert_equal @marshalled, meta
  end


  def test_bracket
    assert Chub::Document === @meta[:foo]
    assert_equal 'bar', @meta[:foo].value
    assert_equal 'thing', @meta[:hsh][:sub]['b'][1].value
  end


  def test_bracket_invalid
    assert_nil @meta[:fwbhgd]
  end


  def test_bracket_assign
    @meta[:foobar] = "FOOBAR!"
    assert_equal "FOOBAR!", @meta[:foobar].value
    assert_equal @metadata, @meta[:foobar].metadata
  end


  def test_bracket_assign_child
    @meta[:arr][3] = "d"
    assert_equal "d", @meta[:arr][3].value
    assert_equal @metadata, @meta[:arr][3].metadata
    assert_equal %w{a b c d}, @meta[:arr].value
  end


  def test_each_hash
    @meta.each do |key, val|
      assert Chub::Document === val,
        "Value at #{key.inspect} was not a Document object"
      assert_equal val.value, @meta[key].value
    end
  end


  def test_each_array
    @meta[:arr].each do |key, val|
      assert Chub::Document === val,
        "Value at #{key.inspect} was not a Document object"
      assert_equal val.value, @meta[:arr][key].value
    end
  end


  def test_each_invalid
    assert_raises NoMethodError do
      @meta[:arr][3].each do |key, val|
      end
    end
  end


  def test_merge_hashes
    metadata = {:user => "jen"}
    data = {:foo => "foobar", :test => "thing"}
    meta1 = Chub::Document.new data, metadata

    new_meta = @meta.merge meta1

    assert_equal "foobar", new_meta[:foo].value
    assert_equal "jen",    new_meta[:foo].metadata[:user]
    assert_equal "thing",  new_meta[:test].value
    assert_equal "jen",    new_meta[:test].metadata[:user]

    assert_equal %w{a b c}, new_meta[:arr].value
    assert_equal "bob",     new_meta[:arr].metadata[:user]
    assert_equal "bob",     new_meta.metadata[:user]
  end


  def test_merge_arrays
    metadata = {:user => "jen"}
    data = [:one, :two]
    meta1 = Chub::Document.new data, metadata

    @meta[:arr].merge! meta1

    assert_equal [:one, :two, "c"], @meta[:arr].value
    assert_equal "bob",             @meta[:arr].metadata[:user]

    assert_equal "jen", @meta[:arr][0].metadata[:user]
    assert_equal "jen", @meta[:arr][1].metadata[:user]
    assert_equal "bob", @meta[:arr][2].metadata[:user]
  end


  def test_merge_hash_array
    metadata = {:user => "jen"}
    data = {:one => "a", :two => "b"}
    meta1 = Chub::Document.new data, metadata

    new_meta = @meta[:arr].merge meta1
    assert_not_equal @meta[:arr].value, new_meta.value

    assert_equal({0 => 'a', 1 => 'b', 2 => 'c', :one => "a", :two => "b"},
                  new_meta.value)

    assert_equal "bob", new_meta.metadata[:user]

    assert_equal "jen", new_meta[:one].metadata[:user]
    assert_equal "jen", new_meta[:two].metadata[:user]
    assert_equal "bob", new_meta[0].metadata[:user]
    assert_equal "bob", new_meta[1].metadata[:user]
    assert_equal "bob", new_meta[2].metadata[:user]
  end


  def test_merge_array_hash
    metadata = {:user => "jen"}
    data = [:one, :two]
    meta1 = Chub::Document.new data, metadata

    @meta[:hsh].merge! meta1

    assert_equal({0 => :one, 1 => :two, :sub => @meta[:hsh][:sub].value},
                  @meta[:hsh].value)

    assert_equal "bob", @meta[:hsh].metadata[:user]

    assert_equal "jen", @meta[:hsh][0].metadata[:user]
    assert_equal "jen", @meta[:hsh][1].metadata[:user]
    assert_equal "bob", @meta[:hsh][:sub].metadata[:user]
  end


  def test_merge_invalid_left
    metadata = {:user => "jen"}
    data = [:one, :two]
    meta1 = Chub::Document.new data, metadata

    @meta[:foo].merge! meta1

    assert_equal 'bar', @meta[:foo].value
    assert_equal 'bob', @meta[:foo].metadata[:user]
  end


  def test_merge_invalid_right
    metadata = {:user => "jen"}
    data = "thing"
    meta1 = Chub::Document.new data, metadata

    @meta[:arr].merge! meta1

    assert_equal %w{a b c}, @meta[:arr].value
    assert_equal 'bob', @meta[:arr].metadata[:user]
  end


  def test_value
    assert_equal @data, @meta.value
    assert_equal @data, Chub::Document.new(@data, "stuff").value
  end


  def test_set_to_hash
    @meta.set :hsh, {:a => :one}, :user => "jen"

    assert_equal({:a => :one}, @meta[:hsh].value)
    assert_equal "jen", @meta[:hsh].metadata[:user]
    assert_equal "jen", @meta[:hsh][:a].metadata[:user]
  end


  def test_set_to_hash_no_metadata
    @meta.set :hsh, {:a => :one}

    assert_equal({:a => :one}, @meta[:hsh].value)
    assert_equal "bob", @meta[:hsh].metadata[:user]
    assert_equal "bob", @meta[:hsh][:a].metadata[:user]
  end


  def test_set_to_meta
    metadata = {:user => "jen"}
    data = "thing"
    meta1 = Chub::Document.new data, metadata

    @meta.set :hsh, meta1

    assert_equal "thing", @meta[:hsh].value
    assert_equal "jen", @meta[:hsh].metadata[:user]
  end


  def test_set_to_meta_with_metadata
    metadata = {:user => "jen"}
    data = "thing"
    meta1 = Chub::Document.new data, metadata

    @meta.set :hsh, meta1, :user => "lyn"

    assert_equal "thing", @meta[:hsh].value
    assert_equal "lyn", @meta[:hsh].metadata[:user]
  end


  def test_set_path
    @meta.set_path [:hsh, :sub, 'a'], "test"
    assert_equal "test", @meta[:hsh][:sub]['a'].value
    assert_equal "bob", @meta[:hsh][:sub]['a'].metadata[:user]
  end


  def test_set_path_hash
    @meta.set_path [:hsh, :sub, 'a'], :test => "thing", :nums => %w{1 2 3}

    assert_equal "bob", @meta[:hsh][:sub]['a'].metadata[:user]
    assert_equal "thing", @meta[:hsh][:sub]['a'][:test].value
    assert_equal %w{1 2 3}, @meta[:hsh][:sub]['a'][:nums].value

    assert_equal "bob", @meta[:hsh][:sub]['a'][:nums][0].metadata[:user]
  end


  def test_set_path_array
    @meta.set_path [:hsh, :sub, 'a'], [:a, :b, [:c, :d]]

    assert_equal "bob", @meta[:hsh][:sub]['a'].metadata[:user]
    assert_equal :a, @meta[:hsh][:sub]['a'][0].value
    assert_equal [:c, :d], @meta[:hsh][:sub]['a'][2].value

    assert_equal "bob", @meta[:hsh][:sub]['a'][2][0].metadata[:user]
  end


  def test_set_path_meta
    @meta.set_path [:hsh, :sub, 'a'], [:a, :b, [:c, :d]], :user => "lyn"

    assert_equal "lyn", @meta[:hsh][:sub]['a'].metadata[:user]
    assert_equal :a, @meta[:hsh][:sub]['a'][0].value
    assert_equal [:c, :d], @meta[:hsh][:sub]['a'][2].value

    assert_equal "lyn", @meta[:hsh][:sub]['a'][2][0].metadata[:user]
  end


  def test_set_path_invalid
    assert_raises Chub::Document::InvalidPathError do
      @meta.set_path [0,0,0], "OOPS"
    end

    assert_raises TypeError do
      @meta.set_path [:arr, 'thing'], "OOPS"
    end
  end


  def test_set_path!
    @meta.set_path! [:hsh, :sub, 'a'], "test"
    assert_equal "test", @meta[:hsh][:sub]['a'].value
    assert_equal "bob", @meta[:hsh][:sub]['a'].metadata[:user]
  end


  def test_set_path_hash!
    @meta.set_path! [:hsh, :sub, 'a'], :test => "thing", :nums => %w{1 2 3}

    assert_equal "bob", @meta[:hsh][:sub]['a'].metadata[:user]
    assert_equal "thing", @meta[:hsh][:sub]['a'][:test].value
    assert_equal %w{1 2 3}, @meta[:hsh][:sub]['a'][:nums].value

    assert_equal "bob", @meta[:hsh][:sub]['a'][:nums][0].metadata[:user]
  end


  def test_set_path_array!
    @meta.set_path! [:hsh, :sub, 'a'], [:a, :b, [:c, :d]]

    assert_equal "bob", @meta[:hsh][:sub]['a'].metadata[:user]
    assert_equal :a, @meta[:hsh][:sub]['a'][0].value
    assert_equal [:c, :d], @meta[:hsh][:sub]['a'][2].value

    assert_equal "bob", @meta[:hsh][:sub]['a'][2][0].metadata[:user]
  end


  def test_set_path_meta!
    @meta.set_path! [:hsh, :sub, 'a'], [:a, :b, [:c, :d]], :user => "lyn"

    assert_equal "lyn", @meta[:hsh][:sub]['a'].metadata[:user]
    assert_equal :a, @meta[:hsh][:sub]['a'][0].value
    assert_equal [:c, :d], @meta[:hsh][:sub]['a'][2].value

    assert_equal "lyn", @meta[:hsh][:sub]['a'][2][0].metadata[:user]
  end


  def test_set_path_new_array!
    @meta.set_path! [:foo, 2], "three", :user => "lyn"

    assert_equal "bob", @meta[:foo].metadata[:user]
    assert_equal [nil, nil, "three"], @meta[:foo].value

    assert_equal "lyn", @meta[:foo][0].metadata[:user]
    assert_equal "lyn", @meta[:foo][1].metadata[:user]
    assert_equal "lyn", @meta[:foo][2].metadata[:user]
  end


  def test_set_path_new_hash!
    @meta.set_path! [:foo, :bar], "foobar", :user => "lyn"

    assert_equal "bob", @meta[:foo].metadata[:user]
    assert_equal({:bar => "foobar"}, @meta[:foo].value)
    assert_equal "lyn", @meta[:foo][:bar].metadata[:user]
  end
end

require 'test_helper'

class TestDataBlamer < Test::Unit::TestCase

  def setup
    @paths = [[
      [],
      [:root],
      [:root, :list],
      [:root, :list, 0],
      [:root, :list, 1],
      [:root, :list, 2],
      [:root, :foo],
      [:root, :people],
      [:root, :people, 0],
      [:root, :people, 0, :name],
      [:root, :people, 0, :age],
      [:root, :people, 0, :gender],
      [:root, :people, 1],
      [:root, :people, 1, :name],
      [:root, :people, 1, :age],
      [:root, :people, 1, :gender],
      [:root, :people, 2],
      [:root, :people, 2, :name],
      [:root, :people, 2, :age],
      [:root, :people, 2, :gender]
    ]]

    @revs = [
      {:timestamp => 12347, :author => "jim", :data => {
        :root => {
          :list => ["one", "two", "three"],
          :foo  => "bar",
          :people => [{
            :name   => "bob",
            :age    => 20,
            :gender => :male
          },{
            :name   => "lucy",
            :age    => 24,
            :gender => :female
          },{
            :name   => "jack",
            :age    => 42,
            :gender => :male
          }]}
      }},
      {:timestamp => 12347, :author => "jim", :data => {
        :root => {
          :list => ["one", "two", "three"],
          :foo  => "bar",
          :people => [{
            :name   => "bob",
            :age    => 20,
            :gender => :male
          },{
            :name   => "lucy",
            :age    => 24,
            :gender => :female
          },{
            :name   => "jack",
            :age    => 42,
            :gender => :male
          }]}
      }},
      {:timestamp => 12345, :author => "jan", :data => {
        :root => {
          :list   => ["three", "two", "three"],
          :foo    => "bar",
          :people => [{
            :name   => "bob",
            :age    => 20,
            :gender => :male
          },{
            :name   => "lucy",
            :age    => 24,
            :gender => :female
          },{
            :name   => "bob",
            :age    => 20,
            :gender => :male
          }]
        }
      }},
      {:timestamp => 12346, :author => "tim", :data => {
        :thing => {
          :list   => ["two", "one", "three"],
          :foobar => "bar",
          :people => [{
            :name   => "jack",
            :age    => 20,
            :gender => :male
          },{
            :name   => "bob",
            :age    => 40,
            :gender => :male
          },{
            :name   => "lucy",
            :age    => 24,
            :gender => :female
          }]}}}]

    @blamer = Chub::DataBlamer.new(*@revs)
  end


  def test_compare_hashes
    hash_left  = {"key1" => "val1", "key2" => "val2", "key3" => "val3"}
    hash_right = {"foo" => "val3", "key1" => "val1", "key2" => "bar"}

    meta_left  = Chub::MetaNode.build hash_left.dup,  :user => "bob"
    meta_right = Chub::MetaNode.build hash_right.dup, :user => "jen"

    new_hash = @blamer.compare_hashes meta_left, meta_right

    assert_equal hash_right, new_hash.to_value

    key1 = new_hash.keys.find{|k| k == "key1"}
    assert_equal "bob", key1.meta[:user]
    assert_equal "bob", new_hash["key1"].meta[:user]

    key2 = new_hash.keys.find{|k| k == "key2"}
    assert_equal "bob", key2.meta[:user]
    assert_equal "jen", new_hash["key2"].meta[:user]

    foo = new_hash.keys.find{|k| k == "foo"}
    assert_equal "jen", foo.meta[:user]
    assert_equal "bob", new_hash["foo"].meta[:user]
  end


  def test_compare_hashes_equal
    hash_left  = {"key1" => "val1", "key2" => "val2", "key3" => "val3"}
    hash_right = {"key2" => "val2", "key1" => "val1", "key3" => "val3"}

    meta_left  = Chub::MetaNode.build hash_left.dup,  :user => "bob"
    meta_right = Chub::MetaNode.build hash_right.dup, :user => "jen"

    new_hash = @blamer.compare_hashes meta_left, meta_right

    assert_equal hash_right, new_hash.to_value

    key1 = new_hash.keys.find{|k| k == "key1"}
    assert_equal "bob", key1.meta[:user]
    assert_equal "bob", new_hash["key1"].meta[:user]

    key2 = new_hash.keys.find{|k| k == "key2"}
    assert_equal "bob", key2.meta[:user]
    assert_equal "bob", new_hash["key2"].meta[:user]

    key3 = new_hash.keys.find{|k| k == "key3"}
    assert_equal "bob", key3.meta[:user]
    assert_equal "bob", new_hash["key3"].meta[:user]
  end


  def test_compare_arrays
    arr_left  = ["one", "two", "three", "four", "five"]
    arr_right = ["zero", "one", "two", "four", "five"]

    meta_left  = Chub::MetaNode.build arr_left.dup,  :user => "bob"
    meta_right = Chub::MetaNode.build arr_right.dup, :user => "jen"

    new_arr = @blamer.compare_arrays meta_left, meta_right

    assert_equal arr_right, new_arr.to_value
    assert_equal "jen", new_arr[0].meta[:user]
    assert_equal "bob", new_arr[1].meta[:user]
    assert_equal "bob", new_arr[2].meta[:user]
    assert_equal "bob", new_arr[3].meta[:user]
    assert_equal "bob", new_arr[4].meta[:user]
  end


  def test_compare_arrays_recursive
    arr_left  = ["one", ["two", "three", "four"], "other", ["five", "seven"]]
    arr_right = ["0", "one", ["two", "four"], "other", ["five", "six", "seven"]]

    meta_left  = Chub::MetaNode.build arr_left.dup,  :user => "bob"
    meta_right = Chub::MetaNode.build arr_right.dup, :user => "jen"

    new_arr = @blamer.compare_arrays meta_left, meta_right

    assert_equal arr_right, new_arr.to_value
    assert_equal "jen", new_arr[0].meta[:user]
    assert_equal "bob", new_arr[1].meta[:user]
    assert_equal "jen", new_arr[2].meta[:user]
    assert_equal "bob", new_arr[3].meta[:user]
    assert_equal "jen", new_arr[4].meta[:user]

    assert_equal ["two", "four"], new_arr[2].to_value
    assert_equal "bob", new_arr[2][0].meta[:user]
    assert_equal "bob", new_arr[2][1].meta[:user]

    assert_equal ["five", "six", "seven"], new_arr[4].to_value
    assert_equal "bob", new_arr[4][0].meta[:user]
    assert_equal "jen", new_arr[4][1].meta[:user]
    assert_equal "bob", new_arr[4][2].meta[:user]
  end


  def test_compare_arrays_equal
    arr_left  = ["one", ["two", "three", "four"], "other", ["five", "seven"]]
    arr_right = ["one", ["two", "three", "four"], "other", ["five", "seven"]]

    meta_left  = Chub::MetaNode.build arr_left.dup,  :user => "bob"
    meta_right = Chub::MetaNode.build arr_right.dup, :user => "jen"

    new_arr = @blamer.compare_arrays meta_left, meta_right

    assert_equal arr_left, new_arr.to_value

    0.upto(arr_left.length - 1) do |i|
      assert_equal "bob", new_arr[i].meta[:user],
        "#{new_arr[i].value} was not changed by bob"
    end
  end


  def test_flatten_data
    data      = @revs[0][:data]
    flattened = Chub::DataBlamer.flatten_data data

    assert Hash === flattened

    flattened.each do |path, val|
      assert @paths[0].include?(path), "#{path.inspect} was not found in @paths"

      data_val = nil
      dup_path = path.dup
      expd_val = data

      until dup_path.empty?
        expd_val = expd_val[dup_path.shift]
      end

      assert_equal expd_val, val
    end
  end
end

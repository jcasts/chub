class TestDataBlamer < Test::Unit::TestCase

  def setup
    @paths = [[
      [:root, :list, 0],
      [:root, :list, 1],
      [:root, :list, 2],
      [:root, :foo],
      [:root, :people, 0, :name],
      [:root, :people, 0, :age],
      [:root, :people, 0, :gender],
      [:root, :people, 1, :name],
      [:root, :people, 1, :age],
      [:root, :people, 1, :gender],
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
  end


  def test_flatten_data
    data      = @revs[0][:data]
    flattened = Chub::DataBlamer.flatten_data data

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

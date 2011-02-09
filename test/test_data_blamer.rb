class TestDataBlamer < Test::Unit::TestCase

  def setup
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
    flattened = Chub::DataBlamer.flatten_data @revs[0][:data]
    p flattened
  end
end

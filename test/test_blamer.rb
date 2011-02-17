require 'test_helper'

class TestBlamer < Test::Unit::TestCase

  def setup
    @revs = [
      {:meta => ["11111114", "jim", 5000],
       :data => "line14\nline24\nline3\nline42\nline53"},
      {:meta => ["11111113", "pam", 4000],
       :data => "line1\nline23\nline3\nline42\nline53\nline6"},
      {:meta => ["11111112", "jenny", 3000],
       :data => "line1\nline3\nline42\nline22\nline5"},
      {:meta => ["11111111", "bob", 2000],
       :data => "line1\nline2\nline3\nline4\nline5"}
    ]

    @blamer = Chub::Blamer.new(*@revs)
  end


  def test_create_blame
    out = @blamer.create_blame
    assert_equal @revs[2][:meta], out[0][0]
    assert_equal @revs[0][:meta], out[1][0]
    assert_nil out[2][0]
    assert_equal @revs[1][:meta], out[3][0]
    assert_equal @revs[1][:meta], out[4][0]
  end


  def test_create_blame_not_last_blank
    out = @blamer.create_blame false
    assert_equal @revs[2][:meta], out[0][0]
    assert_equal @revs[0][:meta], out[1][0]
    assert_equal @revs[3][:meta], out[2][0]
    assert_equal @revs[1][:meta], out[3][0]
    assert_equal @revs[1][:meta], out[4][0]
  end


  def test_formatted
    expected = <<-STR
11111112 jenny 3000 0) line14
11111114 jim   5000 1) line24
                    2) line3
11111113 pam   4000 3) line42
11111113 pam   4000 4) line53
STR

    assert_equal expected, @blamer.formatted
  end


  def test_formatted_not_last_blank
    expected = <<-STR
11111112 jenny 3000 0) line14
11111114 jim   5000 1) line24
11111111 bob   2000 2) line3
11111113 pam   4000 3) line42
11111113 pam   4000 4) line53
STR

    assert_equal expected, @blamer.formatted(false)
  end
end

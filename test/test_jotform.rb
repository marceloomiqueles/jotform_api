require 'test/unit'
require 'jotform'

class JotformTest < Test::Unit::TestCase
  def test_english_hello
    assert_equal "hello world", Jotform.hi("english")
  end

  def test_any_hello
    assert_equal "hello world", Jotform.hi("ruby")
  end

  def test_spanish_hello
    assert_equal "hola mundo", Jotform.hi("spanish")
  end
end

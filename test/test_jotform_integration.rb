require 'test/unit'
require 'jotform'

class JotformIntegrationTest < Test::Unit::TestCase
  def setup
    api_key = ENV['JOTFORM_API_KEY']
    omit('Set JOTFORM_API_KEY to run integration tests') if api_key.nil? || api_key.empty?

    base_url = ENV.fetch('JOTFORM_BASE_URL', 'https://api.jotform.com')
    @jotform = Jotform.new(api_key, base_url, 'v1')
  end

  def test_get_user_returns_hash
    response = @jotform.getUser

    assert_not_nil(response)
    assert_kind_of(Hash, response)
  end

  def test_get_usage_returns_hash
    response = @jotform.getUsage

    assert_not_nil(response)
    assert_kind_of(Hash, response)
  end

  def test_get_forms_returns_array_or_hash
    response = @jotform.getForms

    assert_not_nil(response)
    assert(response.is_a?(Array) || response.is_a?(Hash), 'Expected Array or Hash response from getForms')
  end
end

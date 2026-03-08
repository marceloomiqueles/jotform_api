require 'test/unit'
require 'stringio'
require 'jotform'

class JotformTest < Test::Unit::TestCase
  class FakeSuccessResponse < Net::HTTPSuccess
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  class FakeErrorResponse < Net::HTTPServerError
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  def setup
    @jotform = Jotform.new("test-api-key", "http://example.com", "v9")
    @net_http_singleton = class << Net::HTTP; self; end
  end

  def teardown
    restore_net_http_method(:get_response)
    restore_net_http_method(:post_form)
  end

  def test_get_user_calls_expected_endpoint_and_returns_content
    captured_uri = nil

    stub_net_http_method(:get_response) do |uri|
      captured_uri = uri
      FakeSuccessResponse.new({ "content" => { "username" => "marcelo" } }.to_json)
    end

    result = @jotform.getUser

    assert_equal("http://example.com/v9/user?apiKey=test-api-key", captured_uri.to_s)
    assert_equal({ "username" => "marcelo" }, result)
  end

  def test_create_form_webhook_posts_payload_and_returns_content
    captured_uri = nil
    captured_params = nil

    stub_net_http_method(:post_form) do |uri, params|
      captured_uri = uri
      captured_params = params
      FakeSuccessResponse.new({ "content" => { "id" => "wh_1" } }.to_json)
    end

    result = @jotform.createFormWebhook("123", "https://callback.test/hook")

    assert_equal("http://example.com/v9/form/123/webhooks?apiKey=test-api-key", captured_uri.to_s)
    assert_equal({ "webhookURL" => "https://callback.test/hook" }, captured_params)
    assert_equal({ "id" => "wh_1" }, result)
  end

  def test_error_response_returns_nil_and_prints_api_message
    stub_net_http_method(:get_response) do |_uri|
      FakeErrorResponse.new({ "message" => "Invalid API key" }.to_json)
    end

    original_stdout = $stdout
    output = StringIO.new
    $stdout = output

    result = @jotform.getUser

    assert_nil(result)
    assert_match(/Invalid API key/, output.string)
  ensure
    $stdout = original_stdout
  end

  private

  def stub_net_http_method(method_name, &block)
    original_name = "__original_#{method_name}".to_sym
    return if @net_http_singleton.method_defined?(original_name)

    verbose = $VERBOSE
    @net_http_singleton.send(:alias_method, original_name, method_name)
    @net_http_singleton.send(:remove_method, method_name)
    $VERBOSE = nil
    @net_http_singleton.send(:define_method, method_name, &block)
  ensure
    $VERBOSE = verbose
  end

  def restore_net_http_method(method_name)
    original_name = "__original_#{method_name}".to_sym
    return unless @net_http_singleton.method_defined?(original_name)

    @net_http_singleton.send(:alias_method, method_name, original_name)
    @net_http_singleton.send(:remove_method, original_name)
  end
end

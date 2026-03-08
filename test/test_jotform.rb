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

  def test_initialize_sets_default_values
    jotform = Jotform.new

    assert_nil(jotform.apiKey)
    assert_equal("http://api.jotform.com", jotform.baseURL)
    assert_equal("v1", jotform.apiVersion)
  end

  def test_get_forms_calls_expected_endpoint_and_returns_content
    captured_uri = nil

    stub_net_http_method(:get_response) do |uri|
      captured_uri = uri
      FakeSuccessResponse.new({ "content" => [{ "id" => "f1" }] }.to_json)
    end

    result = @jotform.getForms

    assert_equal("http://example.com/v9/user/forms?apiKey=test-api-key", captured_uri.to_s)
    assert_equal([{ "id" => "f1" }], result)
  end

  def test_get_submission_calls_expected_endpoint_and_returns_content
    captured_uri = nil

    stub_net_http_method(:get_response) do |uri|
      captured_uri = uri
      FakeSuccessResponse.new({ "content" => { "id" => "s1" } }.to_json)
    end

    result = @jotform.getSubmission("s1")

    assert_equal("http://example.com/v9/submission/s1?apiKey=test-api-key", captured_uri.to_s)
    assert_equal({ "id" => "s1" }, result)
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

  def test_create_form_submissions_posts_payload_and_returns_content
    captured_uri = nil
    captured_params = nil
    submission_payload = { "submission[3]" => "Marcelo" }

    stub_net_http_method(:post_form) do |uri, params|
      captured_uri = uri
      captured_params = params
      FakeSuccessResponse.new({ "content" => { "submissionID" => "sub_1" } }.to_json)
    end

    result = @jotform.createFormSubmissions("123", submission_payload)

    assert_equal("http://example.com/v9/form/123/submissions?apiKey=test-api-key", captured_uri.to_s)
    assert_equal(submission_payload, captured_params)
    assert_equal({ "submissionID" => "sub_1" }, result)
  end

  def test_get_endpoint_wrappers_call_expected_paths
    cases = [
      [:getUsage, [], "user/usage"],
      [:getSubmissions, [], "user/submissions"],
      [:getSubusers, [], "user/subusers"],
      [:getFolders, [], "user/folders"],
      [:getReports, [], "user/reports"],
      [:getSettings, [], "user/settings"],
      [:getHistory, [], "user/history"],
      [:getForm, ["123"], "form/123"],
      [:getFormQuestions, ["123"], "form/123/questions"],
      [:getFormQuestion, ["123", "7"], "form/123/question/7"],
      [:getFormProperties, ["123"], "form/123/properties"],
      [:getFormProperty, ["123", "title"], "form/123/properties/title"],
      [:getFormSubmissions, ["123"], "form/123/submissions"],
      [:getFormFiles, ["123"], "form/123/files"],
      [:getFormWebhooks, ["123"], "form/123/webhooks"],
      [:getReport, ["r1"], "report/r1"],
      [:getFolder, ["fld1"], "folder/fld1"]
    ]

    cases.each do |method_name, args, path|
      captured_uri = nil
      expected_content = { "endpoint" => path }

      stub_net_http_method(:get_response) do |uri|
        captured_uri = uri
        FakeSuccessResponse.new({ "content" => expected_content }.to_json)
      end

      result = @jotform.send(method_name, *args)

      assert_equal("http://example.com/v9/#{path}?apiKey=test-api-key", captured_uri.to_s)
      assert_equal(expected_content, result)

      restore_net_http_method(:get_response)
    end
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

    verbose = $VERBOSE
    $VERBOSE = nil
    @net_http_singleton.send(:alias_method, method_name, original_name)
    @net_http_singleton.send(:remove_method, original_name)
  ensure
    $VERBOSE = verbose
  end
end

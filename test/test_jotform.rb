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
    restore_net_http_method(:new)
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

  def test_post_endpoint_wrappers_call_expected_paths
    cases = [
      [:updateSettings, [{ "language" => "en" }], "user/settings"],
      [:registerUser, [{ "username" => "john", "password" => "secret" }], "user/register"],
      [:loginUser, [{ "username" => "john", "password" => "secret", "appName" => "app", "access" => "readOnly" }], "user/login"],
      [:cloneForm, ["123"], "form/123/clone"],
      [:createReport, ["123", { "title" => "My Report", "list_type" => "grid" }], "form/123/reports"],
      [:createFolder, [{ "name" => "Ops", "color" => "#FFFFFF" }], "folder"],
      [:createFormWebhook, ["123", "https://callback.test/hook"], "form/123/webhooks"]
    ]

    cases.each do |method_name, args, path|
      captured_uri = nil
      captured_params = nil

      stub_net_http_method(:post_form) do |uri, params|
        captured_uri = uri
        captured_params = params
        FakeSuccessResponse.new({ "content" => { "endpoint" => path } }.to_json)
      end

      result = @jotform.send(method_name, *args)

      assert_equal("http://example.com/v9/#{path}?apiKey=test-api-key", captured_uri.to_s)
      assert_not_nil(captured_params) unless method_name == :cloneForm
      assert_equal({ "endpoint" => path }, result)

      restore_net_http_method(:post_form)
    end
  end

  def test_submission_and_form_payload_transformations
    captured_uri = nil
    captured_params = nil

    stub_net_http_method(:post_form) do |uri, params|
      captured_uri = uri
      captured_params = params
      FakeSuccessResponse.new({ "content" => { "ok" => true } }.to_json)
    end

    @jotform.createFormSubmission("100", { "1" => "A", "2_first" => "John", "3_last" => "Doe" })
    assert_equal("http://example.com/v9/form/100/submissions?apiKey=test-api-key", captured_uri.to_s)
    assert_equal(
      {
        "submission[1]" => "A",
        "submission[2][first]" => "John",
        "submission[3][last]" => "Doe"
      },
      captured_params
    )

    @jotform.editSubmission("sub_1", { "2_first" => "Jane", "created_at" => "2025-01-01" })
    assert_equal("http://example.com/v9/submission/sub_1?apiKey=test-api-key", captured_uri.to_s)
    assert_equal(
      {
        "submission[2][first]" => "Jane",
        "submission[created_at]" => "2025-01-01"
      },
      captured_params
    )

    @jotform.createFormQuestion("100", { "type" => "control_head", "text" => "Header" })
    assert_equal("http://example.com/v9/form/100/questions?apiKey=test-api-key", captured_uri.to_s)
    assert_equal({ "question[type]" => "control_head", "question[text]" => "Header" }, captured_params)

    @jotform.editFormQuestion("100", "7", { "text" => "Updated" })
    assert_equal("http://example.com/v9/form/100/question/7?apiKey=test-api-key", captured_uri.to_s)
    assert_equal({ "question[text]" => "Updated" }, captured_params)

    @jotform.setFormProperties("100", { "thankurl" => "https://example.com/thanks", "formWidth" => "650" })
    assert_equal("http://example.com/v9/form/100/properties?apiKey=test-api-key", captured_uri.to_s)
    assert_equal(
      {
        "properties[thankurl]" => "https://example.com/thanks",
        "properties[formWidth]" => "650"
      },
      captured_params
    )

    form_payload = {
      "questions" => { "0" => { "type" => "control_head", "text" => "Form Title" } },
      "properties" => { "title" => "New Form" },
      "emails" => { "0" => { "type" => "notification", "to" => "noreply@jotform.com" } }
    }
    @jotform.createForm(form_payload)
    assert_equal("http://example.com/v9/user/forms?apiKey=test-api-key", captured_uri.to_s)
    assert_equal(
      {
        "questions[0][type]" => "control_head",
        "questions[0][text]" => "Form Title",
        "properties[title]" => "New Form",
        "emails[0][type]" => "notification",
        "emails[0][to]" => "noreply@jotform.com"
      },
      captured_params
    )
  end

  def test_create_label_posts_payload_and_returns_content
    captured_uri = nil
    captured_params = nil
    payload = { "name" => "IT Operations", "color" => "#FFDC7B" }

    stub_net_http_method(:post_form) do |uri, params|
      captured_uri = uri
      captured_params = params
      FakeSuccessResponse.new({ "content" => { "id" => "lbl_1" } }.to_json)
    end

    result = @jotform.createLabel(payload)

    assert_equal("http://example.com/v9/label?apiKey=test-api-key", captured_uri.to_s)
    assert_equal(payload, captured_params)
    assert_equal({ "id" => "lbl_1" }, result)
  end

  def test_put_and_delete_label_requests_use_expected_paths_and_payloads
    captured = {}

    stub_net_http_method(:new) do |host, port|
      captured[:host] = host
      captured[:port] = port

      http = Object.new
      http.define_singleton_method(:use_ssl=) do |value|
        captured[:use_ssl] = value
      end
      http.define_singleton_method(:request) do |request|
        captured[:request] = request
        FakeSuccessResponse.new({ "content" => { "ok" => true } }.to_json)
      end
      http
    end

    update_payload = { "name" => "Workplace Operations", "color" => "#23FFDD" }
    update_result = @jotform.updateLabel("label_1", update_payload)

    assert_equal("example.com", captured[:host])
    assert_equal(80, captured[:port])
    assert_equal(false, captured[:use_ssl])
    assert_kind_of(Net::HTTP::Put, captured[:request])
    assert_equal("/v9/label/label_1?apiKey=test-api-key", captured[:request].path)
    assert_equal(update_payload.to_json, captured[:request].body)
    assert_equal("application/json", captured[:request]["Content-Type"])
    assert_equal({ "ok" => true }, update_result)

    resources = [{ "id" => "251464995493876", "type" => "form" }]
    add_result = @jotform.addResourcesToLabel("label_1", resources)
    assert_equal("/v9/label/label_1/add-resources?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "resources" => resources }.to_json, captured[:request].body)
    assert_equal({ "ok" => true }, add_result)

    remove_result = @jotform.removeResourcesFromLabel("label_1", resources)
    assert_equal("/v9/label/label_1/remove-resources?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "resources" => resources }.to_json, captured[:request].body)
    assert_equal({ "ok" => true }, remove_result)

    @jotform.updateFolder("folder_1", { "name" => "My Folder" })
    assert_equal("/v9/folder/folder_1?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "name" => "My Folder" }.to_json, captured[:request].body)

    @jotform.addFormsToFolder("folder_1", ["f1", "f2"])
    assert_equal("/v9/folder/folder_1?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "forms" => ["f1", "f2"] }.to_json, captured[:request].body)

    @jotform.addFormToFolder("folder_1", "f3")
    assert_equal("/v9/folder/folder_1?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "forms" => ["f3"] }.to_json, captured[:request].body)

    @jotform.createForms([{ "properties" => { "title" => "Bulk" } }])
    assert_equal("/v9/user/forms?apiKey=test-api-key", captured[:request].path)
    assert_equal([{ "properties" => { "title" => "Bulk" } }].to_json, captured[:request].body)

    @jotform.createFormQuestions("100", { "questions" => {} })
    assert_equal("/v9/form/100/questions?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "questions" => {} }.to_json, captured[:request].body)

    @jotform.setMultipleFormProperties("100", { "properties" => { "labelWidth" => "150" } })
    assert_equal("/v9/form/100/properties?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "properties" => { "labelWidth" => "150" } }.to_json, captured[:request].body)

    raw_payload = '{"name":"Raw Label"}'
    raw_result = @jotform.updateLabel("label_1", raw_payload)
    assert_equal("/v9/label/label_1?apiKey=test-api-key", captured[:request].path)
    assert_equal(raw_payload, captured[:request].body)
    assert_equal("application/json", captured[:request]["Content-Type"])
    assert_equal({ "ok" => true }, raw_result)

    delete_result = @jotform.deleteLabel("label_1")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/label/label_1?apiKey=test-api-key", captured[:request].path)
    assert_equal({ "ok" => true }, delete_result)

    @jotform.deleteFolder("folder_1")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/folder/folder_1?apiKey=test-api-key", captured[:request].path)

    @jotform.deleteFormWebhook("100", "wh_1")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/form/100/webhooks/wh_1?apiKey=test-api-key", captured[:request].path)

    @jotform.deleteSubmission("sub_1")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/submission/sub_1?apiKey=test-api-key", captured[:request].path)

    @jotform.deleteFormQuestion("100", "7")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/form/100/question/7?apiKey=test-api-key", captured[:request].path)

    @jotform.deleteForm("100")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/form/100?apiKey=test-api-key", captured[:request].path)

    @jotform.deleteReport("rep_1")
    assert_kind_of(Net::HTTP::Delete, captured[:request])
    assert_equal("/v9/report/rep_1?apiKey=test-api-key", captured[:request].path)
  end

  def test_get_endpoint_wrappers_call_expected_paths
    cases = [
      [:getUsage, [], "user/usage"],
      [:getLabels, [], "user/labels"],
      [:getInvoices, [], "user/invoices"],
      [:getSubmissions, [], "user/submissions"],
      [:getSubusers, [], "user/subusers"],
      [:getFolders, [], "user/folders"],
      [:getReports, [], "user/reports"],
      [:getSettings, [], "user/settings"],
      [:getUserSetting, ["language"], "user/settings/language"],
      [:getHistory, [], "user/history"],
      [:logoutUser, [], "user/logout"],
      [:getSystemPlan, ["FREE"], "system/plan/FREE"],
      [:getForm, ["123"], "form/123"],
      [:getFormQuestions, ["123"], "form/123/questions"],
      [:getFormQuestion, ["123", "7"], "form/123/question/7"],
      [:getFormProperties, ["123"], "form/123/properties"],
      [:getFormProperty, ["123", "title"], "form/123/properties/title"],
      [:getFormSubmissions, ["123"], "form/123/submissions"],
      [:getFormFiles, ["123"], "form/123/files"],
      [:getFormWebhooks, ["123"], "form/123/webhooks"],
      [:getFormReports, ["123"], "form/123/reports"],
      [:getReport, ["r1"], "report/r1"],
      [:getFolder, ["fld1"], "folder/fld1"],
      [:getLabel, ["lbl1"], "label/lbl1"],
      [:getLabelResources, ["lbl1"], "label/lbl1/resources"]
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

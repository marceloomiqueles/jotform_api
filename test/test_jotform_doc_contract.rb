require 'test/unit'
require 'open-uri'

class JotformDocContractTest < Test::Unit::TestCase
  DOCS_URL = 'https://api.jotform.com/docs/'.freeze

  SUPPORTED_ENDPOINTS = [
    'user',
    'user/forms',
    'user/folders',
    'user/invoices',
    'user/history',
    'user/settings',
    'user/settings/{settingsKey}',
    'user/subusers',
    'user/usage',
    'user/reports',
    'user/register',
    'user/login',
    'user/logout',
    'user/submissions',
    'user/labels',
    'form/{formID}',
    'form/{formID}/clone',
    'form/{formID}/files',
    'form/{formID}/properties',
    'form/{formID}/properties/{propertyKey}',
    'form/{formID}/question/{questionID}',
    'form/{formID}/questions',
    'form/{formID}/reports',
    'form/{formID}/submissions',
    'form/{formID}/webhooks',
    'form/{formID}/webhooks/{webhookID}',
    'report/{reportID}',
    'submission/{submissionID}',
    'folder',
    'folder/{folderID}',
    'system/plan/{planName}',
    'label',
    'label/{labelID}',
    'label/{labelID}/resources',
    'label/{labelID}/add-resources',
    'label/{labelID}/remove-resources'
  ].freeze

  def test_docs_endpoints_are_covered_by_client_contract
    omit('Set RUN_DOC_CONTRACT=1 to run doc contract test') unless ENV['RUN_DOC_CONTRACT'] == '1'

    html = URI.open(DOCS_URL, &:read)
    documented = extract_documented_endpoints(html)
    missing = documented - SUPPORTED_ENDPOINTS

    assert(
      missing.empty?,
      "Documented endpoints missing from client contract:\n#{missing.sort.join("\n")}"
    )
  end

  private

  def extract_documented_endpoints(html)
    endpoints = html.scan(%r{https://api\.jotform\.com/(?:v1/)?[a-zA-Z0-9_\-\{\}/]+}).map do |full|
      normalize_endpoint(full.sub('https://api.jotform.com/', ''))
    end

    endpoints.reject { |ep| ep.nil? || ep == 'docs/' }.uniq.sort
  end

  def normalize_endpoint(endpoint)
    ep = endpoint.dup
    ep = ep.sub(%r{\Av1/}, '')
    ep = ep.sub('{myFormID}', '{formID}')
    ep = ep.sub(%r{\Asystem/plan/[^/]+\z}, 'system/plan/{planName}')
    ep = ep.sub(%r{\Aform\z}, 'user/forms')
    ep = ep.sub(%r{\Alabel/[0-9a-f]{20,}\z}, 'label/{labelID}')
    ep = ep.sub(%r{\Alabel/[0-9a-f]{20,}/resources\z}, 'label/{labelID}/resources')
    ep = ep.sub(%r{\Alabel/[0-9a-f]{20,}/add-resources\z}, 'label/{labelID}/add-resources')
    ep = ep.sub(%r{\Alabel/[0-9a-f]{20,}/remove-resources\z}, 'label/{labelID}/remove-resources')
    ep
  end
end

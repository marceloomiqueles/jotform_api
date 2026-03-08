class Jotform
  attr_accessor :apiKey
  attr_accessor :baseURL
  attr_accessor :apiVersion

  # Create the object
  def initialize(apiKey = nil, baseURL = "http://api.jotform.com", apiVersion = "v1")
    @apiKey = apiKey
    @baseURL = baseURL
    @apiVersion = apiVersion
  end

  def _executeHTTPRequest(endpoint, parameters = nil, type = "GET")
    url = [@baseURL, @apiVersion, endpoint].join("/").concat('?apiKey='+@apiKey)
    url = URI.parse(url)

    if type == "GET"
      response = Net::HTTP.get_response(url)
    elsif type == "POST"
      response = Net::HTTP.post_form(url, parameters)
    elsif type == "PUT" || type == "DELETE"
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == "https")

      if type == "PUT"
        request = Net::HTTP::Put.new(url.request_uri)
        if parameters
          if parameters.is_a?(String)
            request.body = parameters
          else
            request.body = JSON.generate(parameters)
          end
          request["Content-Type"] = "application/json"
        end
      else
        request = Net::HTTP::Delete.new(url.request_uri)
      end

      response = http.request(request)
    end

    if response.kind_of? Net::HTTPSuccess
      return JSON.parse(response.body)["content"]
    else
      puts JSON.parse(response.body)["message"]
      return nil
    end
  end

  def _executeGetRequest(endpoint, parameters = [])
    return _executeHTTPRequest(endpoint,parameters, "GET")
  end

  def _executePostRequest(endpoint, parameters = [])
    return _executeHTTPRequest(endpoint,parameters, "POST")
  end

  def _executePutRequest(endpoint, parameters = [])
    return _executeHTTPRequest(endpoint,parameters, "PUT")
  end

  def _executeDeleteRequest(endpoint, parameters = [])
    return _executeHTTPRequest(endpoint,parameters, "DELETE")
  end

  def getUser
    return _executeGetRequest("user")
  end

  def getUsage
    return _executeGetRequest("user/usage")
  end

  def getForms
    return _executeGetRequest("user/forms")
  end

  def getSubmissions
    return _executeGetRequest("user/submissions")
  end

  def getSubusers
    return _executeGetRequest("user/subusers")
  end

  def getFolders
    return _executeGetRequest("user/folders")
  end

  def getReports
    return _executeGetRequest("user/reports")
  end

  def getSettings
    return _executeGetRequest("user/settings")
  end

  def getHistory
    return _executeGetRequest("user/history")
  end

  def getLabels
    return _executeGetRequest("user/labels")
  end

  def getForm(formID)
    return _executeGetRequest("form/"+ formID)
  end

  def getFormQuestions(formID)
    return _executeGetRequest("form/"+formID+"/questions")
  end

  def getFormQuestion(formID, qid)
    return _executeGetRequest("form/"+formID+"/question/"+qid)
  end

  def getFormProperties(formID)
    return _executeGetRequest("form/"+formID+"/properties")
  end

  def getFormProperty(formID, propertyKey)
    return _executeGetRequest("form/"+formID+"/properties/"+propertyKey)
  end

  def getFormSubmissions(formID)
    return _executeGetRequest("form/" + formID + "/submissions")
  end

  def getFormFiles(formID)
    return _executeGetRequest("form/"+formID+"/files")
  end

  def getFormWebhooks(formID)
    return _executeGetRequest("form/"+formID+"/webhooks")
  end

  def getSubmission(sid)
    return _executeGetRequest("submission/"+sid)
  end

  def getReport(reportID)
    return _executeGetRequest("report/"+reportID)
  end

  def getFolder(folderID)
    return _executeGetRequest("folder/"+folderID)
  end

  def getSystemPlan(planName)
    return _executeGetRequest("system/plan/"+planName)
  end

  def getLabel(labelID)
    return _executeGetRequest("label/"+labelID)
  end

  def getLabelResources(labelID)
    return _executeGetRequest("label/"+labelID+"/resources")
  end

  def createFormWebhook(formID, webhookURL)
    return _executePostRequest("form/"+formID+"/webhooks",{"webhookURL" => webhookURL} )
  end

  def createFormSubmissions(formID, submission)
    return _executePostRequest("form/" + formID + "/submissions", submission)
  end

  def createLabel(labelProperties)
    return _executePostRequest("label", labelProperties)
  end

  def updateLabel(labelID, labelProperties)
    return _executePutRequest("label/" + labelID, labelProperties)
  end

  def addResourcesToLabel(labelID, resources)
    return _executePutRequest("label/" + labelID + "/add-resources", { "resources" => resources })
  end

  def removeResourcesFromLabel(labelID, resources)
    return _executePutRequest("label/" + labelID + "/remove-resources", { "resources" => resources })
  end

  def deleteLabel(labelID)
    return _executeDeleteRequest("label/" + labelID)
  end
end

require "net/http"
require "uri"
require "rubygems"
require "json"

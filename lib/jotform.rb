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

  def getUserSetting(settingKey)
    return _executeGetRequest("user/settings/" + settingKey)
  end

  def updateSettings(settings)
    return _executePostRequest("user/settings", settings)
  end

  def getHistory
    return _executeGetRequest("user/history")
  end

  def getLabels
    return _executeGetRequest("user/labels")
  end

  def getInvoices
    return _executeGetRequest("user/invoices")
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

  def getFormReports(formID)
    return _executeGetRequest("form/" + formID + "/reports")
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

  def createFormSubmission(formID, submission)
    formatted_submission = {}
    submission.each do |key, value|
      key_string = key.to_s
      if key_string.include?("_")
        qid, field_type = key_string.split("_", 2)
        formatted_submission["submission[#{qid}][#{field_type}]"] = value
      else
        formatted_submission["submission[#{key_string}]"] = value
      end
    end

    return _executePostRequest("form/" + formID + "/submissions", formatted_submission)
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

  def createFolder(folderProperties)
    return _executePostRequest("folder", folderProperties)
  end

  def updateFolder(folderID, folderProperties)
    return _executePutRequest("folder/" + folderID, folderProperties)
  end

  def deleteFolder(folderID)
    return _executeDeleteRequest("folder/" + folderID)
  end

  def addFormsToFolder(folderID, formIDs)
    return updateFolder(folderID, { "forms" => formIDs })
  end

  def addFormToFolder(folderID, formID)
    return addFormsToFolder(folderID, [formID])
  end

  def deleteFormWebhook(formID, webhookID)
    return _executeDeleteRequest("form/" + formID + "/webhooks/" + webhookID)
  end

  def deleteSubmission(submissionID)
    return _executeDeleteRequest("submission/" + submissionID)
  end

  def editSubmission(submissionID, submission)
    formatted_submission = {}
    submission.each do |key, value|
      key_string = key.to_s
      if key_string.include?("_") && key_string != "created_at"
        qid, field_type = key_string.split("_", 2)
        formatted_submission["submission[#{qid}][#{field_type}]"] = value
      else
        formatted_submission["submission[#{key_string}]"] = value
      end
    end

    return _executePostRequest("submission/" + submissionID, formatted_submission)
  end

  def cloneForm(formID)
    return _executePostRequest("form/" + formID + "/clone", nil)
  end

  def deleteFormQuestion(formID, qid)
    return _executeDeleteRequest("form/" + formID + "/question/" + qid)
  end

  def createFormQuestion(formID, question)
    formatted_question = {}
    question.each do |key, value|
      formatted_question["question[#{key}]"] = value
    end

    return _executePostRequest("form/" + formID + "/questions", formatted_question)
  end

  def createFormQuestions(formID, questions)
    return _executePutRequest("form/" + formID + "/questions", questions)
  end

  def editFormQuestion(formID, qid, questionProperties)
    formatted_question = {}
    questionProperties.each do |key, value|
      formatted_question["question[#{key}]"] = value
    end

    return _executePostRequest("form/" + formID + "/question/" + qid, formatted_question)
  end

  def setFormProperties(formID, formProperties)
    formatted_properties = {}
    formProperties.each do |key, value|
      formatted_properties["properties[#{key}]"] = value
    end

    return _executePostRequest("form/" + formID + "/properties", formatted_properties)
  end

  def setMultipleFormProperties(formID, formProperties)
    return _executePutRequest("form/" + formID + "/properties", formProperties)
  end

  def createForm(form)
    formatted_form = {}
    form.each do |section, values|
      values.each do |key, value|
        if section.to_s == "properties"
          formatted_form["#{section}[#{key}]"] = value
        else
          value.each do |sub_key, sub_value|
            formatted_form["#{section}[#{key}][#{sub_key}]"] = sub_value
          end
        end
      end
    end

    return _executePostRequest("user/forms", formatted_form)
  end

  def createForms(forms)
    return _executePutRequest("user/forms", forms)
  end

  def deleteForm(formID)
    return _executeDeleteRequest("form/" + formID)
  end

  def registerUser(userDetails)
    return _executePostRequest("user/register", userDetails)
  end

  def loginUser(credentials)
    return _executePostRequest("user/login", credentials)
  end

  def logoutUser
    return _executeGetRequest("user/logout")
  end

  def createReport(formID, report)
    return _executePostRequest("form/" + formID + "/reports", report)
  end

  def deleteReport(reportID)
    return _executeDeleteRequest("report/" + reportID)
  end
end

require "net/http"
require "uri"
require "rubygems"
require "json"

module SfdcBulkApiBase
	extend ActiveSupport::Concern

	included do
    attr_accessor :current_job
   end

  def session_id
    @connection ||= SfdcBulk::Connection.new
    @connection.session_id
  end


  def base_sfdc_url
    instance = $sfdcbulk_configuration.sfdc_instance
    api_version = $sfdcbulk_configuration.sfdc_api_version

    "https://#{instance}.salesforce.com/services/async/#{api_version}"

  end

  def call_api(service,params=nil,options={},&block)
    RestClient.log = 'stdout'

    session_id
    bulk_api_url = "#{base_sfdc_url}/#{service}"

    Rails.logger.info("call api #{self.class.sobject}: #{bulk_api_url}")

    headers = { 
      "X-SFDC-Session" => session_id , 
      "charset" => "UTF-8", 
      "Content-Type"=> "application/xml"
    }.merge(options)
    
    result = if params.nil?
      RestClient.get bulk_api_url,headers
    else
      RestClient.post bulk_api_url,params,headers
    end

    if block
      result = HashWithIndifferentAccess.from_xml(result)
      yield result
    else
      result
    end
  end
end
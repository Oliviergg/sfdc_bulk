module SfdcBulk
  class SfdcUpsertApi < SfdcApi
    attr_accessor :job_id, :batch_id, :result_id


    def sobject
      self.class.sobject
    end

    def self.external_id
      "external_id__c"
    end


    def create_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo
    xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <operation>upsert</operation>
  <object>#{self.class.sobject}</object>
  <externalIdFieldName>#{self.class.external_id}</externalIdFieldName>
  <concurrencyMode>Parallel</concurrencyMode>  
  <contentType>XML</contentType>
</jobInfo>
      XML
    end

    def initialize(origs)
      @origs = origs
    end


    def run
      start_new_job
      start_new_batch

      completed = false
      sleep 10
      while !is_completed_batch
        sleep 30 
      end

      # get_result_ids
      # filename = result_to_file

      close_job
    end

    def start_new_batch
      data = self.as_xml
      @batch_id = call_api(batch,data, {"Content-Type"=> "application/xml"}) do |result|
        result["batchInfo"]["id"]
      end
    end

    def as_xml

      return <<-XMLDATA
<?xml version="1.0" encoding="UTF-8"?>
<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
#{@origs.map do |orig|
    "\t<sObject>\n" + map_one(orig).map do |k,v|
        "\t\t<#{k.to_s}>#{v}</#{k.to_s}>"
      end.join("\n") + "\n\t</sObject>"
    end.join("\n") 
    }   
</sObjects>
XMLDATA
    end

  end
end
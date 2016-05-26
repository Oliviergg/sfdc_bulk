module SfdcBulk
  class SfdcUpdateApi 
    include SfdcBulkUpdateApi
    include SfdcBulkApiBase


	def initialize(payload)
		@payload = payload
	end

  def payload_to_xml(payload_part)
    return <<-XMLDATA
<?xml version="1.0" encoding="UTF-8"?>
<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
#{payload_part.map do |orig|
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
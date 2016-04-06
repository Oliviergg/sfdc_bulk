module SfdcBulk

	class Connection
			attr_reader :response, :api_version, :instance
			def initialize
				print "-----------------------------------------------------\n"
				print "login on #{$sfdcbulk_configuration.sfdc_login_endpoint}\n"
				print "as #{self.config[:username]}\n"
				print "-----------------------------------------------------\n"
			end
			
			def config
				@config ||= {
					username: $sfdcbulk_configuration.sfdc_user_name,
					password:"#{$sfdcbulk_configuration.sfdc_password}#{$sfdcbulk_configuration.sfdc_security_token}",
					login:{
						endpoint: $sfdcbulk_configuration.sfdc_login_endpoint,
				 		namespace:"urn:enterprise.soap.sforce.com",
				 		# pretty_print_xml:true,
				 		# log: true
					}
				}
			end

			def session_id

				return @session_id unless @session_id.nil?
				login_response = ::Savon.client(self.config[:login]).call(:login ,message:{
					username: self.config[:username],
					password: self.config[:password],
				})

				@response = login_response.body[:login_response][:result]
				@session_id = @response[:session_id]

				res = response[:server_url].match(/https:\/\/(.*)\.salesforce\.com\/services\/Soap\/c\/([0-9\.]+)/)
				@instance = res[1] 
				@api_version = res[2]
				$sfdcbulk_configuration.sfdc_instance = @instance
				$sfdcbulk_configuration.sfdc_api_version = @api_version

				@session_id
			end

	end

end
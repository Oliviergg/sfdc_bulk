module SfdcBulk

	class Connection
		# include SFDC::Proxy			
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
				 		pretty_print_xml:true,
				 		log: true
					}
				}
			end

			def session_id

				return @session_id unless @session_id.nil?
				login_response = ::Savon.client(self.config[:login]).call(:login ,message:{
					username: self.config[:username],
					password: self.config[:password],
				})

				@session_id = login_response.body[:login_response][:result][:session_id]
			end

	end

end
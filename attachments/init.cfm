<cffunction name="init" access="public" output="false" returntype="any">
	<cfset this.version = "1.1,1.1.1,1.2,1.1.3" />
	
	<!--- setup defaults for our new methods --->
	<cfset application.wheels.functions.validatesAttachmentPresenceOf = {message="[property] can't be empty"} />

	<cfreturn this />
</cffunction>

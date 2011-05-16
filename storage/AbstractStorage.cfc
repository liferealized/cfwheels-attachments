<cfinterface>

	<cffunction name="init" access="public" output="false" returntype="any" />

	<cffunction name="exists" access="public" description="See if a file exists on the storage mechanism." output="false" returntype="boolean">
		<cfargument name="path" type="string" required="true" />
	</cffunction>
	
	<cffunction name="write" access="public" description="Write a file to the stoage mechanism." output="false" returntype="boolean">
		<cfargument name="source" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
	</cffunction>

	<cffunction name="delete" access="public" description="Delete a file from the storage mechanism." output="false" returntype="boolean">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="directory" type="boolean" required="false" default="false">
		<cfargument name="recursive" type="boolean" required="false" default="false">
	</cffunction>

</cfinterface>
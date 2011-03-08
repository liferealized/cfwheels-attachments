<cfcomponent implements="AbstractStorage" output="false">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset var loc = {} />
		<cfinclude template="../settings.cfm" />
		<cfset variables.class = Duplicate(loc) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="exists" access="public" output="false" returntype="boolean">
		<cfargument name="path" type="string" required="true" />
		<cfreturn FileExists($expandS3Path(arguments.path)) />
	</cffunction>
	
	<cffunction name="write" access="public" output="false" returntype="boolean">
		<cfargument name="source" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfscript>
			FileCopy(arguments.source, $expandS3Path(arguments.path));
			// we also need to set the acl for the object
			StoreAddACL($expandS3Path(arguments.path), $getAcl());
		</cfscript>
		<cfreturn true />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="boolean">
		<cfargument name="path" type="string" required="true" />
		<cfscript>
			try
			{
				FileDelete($expandS3Path(arguments.path));
			}
			catch (Any e)
			{
				return false;
			}
		</cfscript>
		<cfreturn true />
	</cffunction>
	
	<cffunction name="$getAcl" access="private" output="false" returntype="array">
		<cfreturn variables.class.acl />
	</cffunction>
	
	<cffunction name="$expandS3Path" access="private" output="false" returntype="string">
		<cfargument name="path" type="string" required="true" />
		<cfreturn "s3://#variables.class.accessKey#:#variables.class.secretKey#@#variables.class.bucketName##arguments.path#" />
	</cffunction>

</cfcomponent>
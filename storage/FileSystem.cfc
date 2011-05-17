<cfcomponent implements="AbstractStorage" output="false">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset var loc = {} />
		<cfinclude template="../settings.cfm" />
		<cfset variables.class = Duplicate(loc) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="exists" access="public" output="false" returntype="boolean">
		<cfargument name="path" type="string" required="true" />
		<cfreturn FileExists(ExpandPath(arguments.path)) />
	</cffunction>
	
	<cffunction name="write" access="public" output="false" returntype="boolean">
		<cfargument name="source" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfscript>
			var loc = {};
			
			loc.directory = ExpandPath(Reverse(ListRest(Reverse(arguments.path), "/")));
			
			if (!DirectoryExists(loc.directory))
				$directory(action="create", directory=loc.directory);
			
			FileCopy(arguments.source, ExpandPath(arguments.path));
		</cfscript>
		<cfreturn true />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="boolean">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="directory" type="boolean" required="false" default="false">
		<cfargument name="recursive" type="boolean" required="false" default="false">
		<cfscript>
			try
			{
				if (arguments.directory)
				{
					DirectoryDelete(ExpandPath(arguments.path), arguments.recursive);
				}
				else
				{
					FileDelete(ExpandPath(arguments.path));
				}
			}
			catch (Any e)
			{
				return false;
			}
		</cfscript>
		<cfreturn true />
	</cffunction>

	<cffunction name="$directory" access="private" output="false" returntype="any">
		<cfset var returnValue = "">
		<cfset arguments.name = "returnValue">
		<cfdirectory attributeCollection="#arguments#">
		<cfreturn returnValue>
	</cffunction>

</cfcomponent>
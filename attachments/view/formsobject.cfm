<!---
	we need a way to know what the fileField / fileFieldTag fieldname is for uploading purposes
--->	
<cffunction name="fileField" access="public" output="false" returntype="string" mixin="controller">
	<cfscript>
		var loc = { args = {}, returnValue = "" };
		var coreFileField = core.fileField;
		$args(name="fileField", reserved="type,name", args=arguments);
		
		// just in case developers (like me) do crazy stuff with their form fields
		loc.property = arguments.property;
		if (arguments.property contains "]")
			loc.property = Reverse(Replace(Reverse(arguments.property), "]", "", "one")) & "$attachment]";
		else
			loc.property &= "$attachment";
		
		// create the id
		if (StructKeyExists(arguments, "id"))
			loc.args.id = arguments.id & "$attachment";
		else
			loc.args.id = $tagId(arguments.objectName, loc.property);
		
		// create the name and value for our hidden tag
		loc.args.name = $tagName(arguments.objectName, loc.property);
		loc.args.value = $tagName(arguments.objectName, arguments.property);
		
		loc.returnValue &= hiddenFieldTag(argumentCollection=loc.args);
		loc.returnValue &= coreFileField(argumentCollection=arguments);
	</cfscript>
	<cfreturn loc.returnValue />
</cffunction>

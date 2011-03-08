<!--- 
	new validation methods for attachments
--->
<cffunction name="validatesAttachmentPresenceOf" access="public" output="false" returntype="void" mixin="model">
	<cfargument name="properties" type="string" required="false" default="" />
	<cfargument name="message" type="string" required="false" />
	<cfargument name="when" type="string" required="false" default="onSave" />
	<cfargument name="if" type="string" required="false" default="" />
	<cfargument name="unless" type="string" required="false" default="" />
	<cfset $args(name="validatesPresenceOf", args=arguments) />
	<cfset $registerValidation(methods="$validatesAttachmentPresenceOf", argumentCollection=arguments) />
</cffunction>

<cffunction name="$validatesAttachmentPresenceOf" access="public" output="false" returntype="void" mixin="model">
	<cfscript>
		var returnValue = false;
		// if the property does not exist 
		// or if it's blank
		// or if it is not a .tmp file we add an error on the object (for all other validation types we call corresponding methods below instead)
		if (!StructKeyExists(this, arguments.property) or (IsSimpleValue(this[arguments.property]) and !Len(Trim(this[arguments.property])) and !Find(".tmp", this[arguments.property])) or (IsStruct(this[arguments.property]) and !StructCount(this[arguments.property])))
			returnValue = true;
	</cfscript>
	<cfreturn returnValue />
</cffunction>

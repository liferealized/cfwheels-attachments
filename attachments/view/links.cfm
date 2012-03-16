<cffunction name="attachmentLinkTo" returntype="string" access="public" output="false" hint="Creates a link to an attachment uploaded via the Attachments plugin. Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.">
	<cfargument name="text" type="string" required="false" default="" hint="The text content of the link.">
	<cfargument name="attachment" required="false" default="" hint="Pass an attachment property struct here to use an attachment. Can be a struct or JSON-formatted.">
	<cfargument name="attachmentStyle" required="false" default="" hint="Pass an attachment style name here to use a particular attachment's style.">
	<cfscript>
		var loc = {
			linkToArgs=Duplicate(arguments),
			skip="text,confirm,route,controller,action,key,params,anchor,onlyPath,host,protocol,port"
		};
		
		// Remove non-string values
		StructDelete(loc.linkToArgs, "attachment");
		StructDelete(loc.linkToArgs, "attachmentStyle");

		if (IsJson(arguments.attachment))
			arguments.attachment = DeserializeJson(arguments.attachment);

		if (Len(arguments.attachmentStyle))
			loc.linkToArgs.href = arguments.attachment.styles[arguments.style].url;
		else
			loc.linkToArgs.href = arguments.attachment.url;

		if (!Len(loc.linkToArgs.text))
			loc.linkToArgs.text = loc.linkToArgs.href;

		loc.returnValue = $element(name="a", skip=loc.skip, content=loc.linkToArgs.text, attributes=loc.linkToArgs);
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>
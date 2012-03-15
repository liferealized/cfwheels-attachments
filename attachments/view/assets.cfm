<cffunction name="imageTag" returntype="string" mixin="controller" hint="Returns an image tag built for attachments. Otherwise, follows normal `imageTag()` behavior.">
	<cfargument name="source" type="string" required="false" default="" hint="The file name of the image if it's availabe in the local file system (i.e. ColdFusion will be able to access it). Provide the full URL if the image is on a remote server.">
	<cfargument name="attachment" required="false" default="" hint="Pass an attachment property struct here to use an attachment.">
	<cfargument name="attachmentStyle" required="false" default="" hint="Pass an attachment style name here to use a particular attachment's style.">
	<cfscript>
		var loc = {
			coreImageTag=core.imageTag,
			imageTagArgs=Duplicate(arguments)
		};

		// Remove non-string values
		StructDelete(loc.imageTagArgs, "attachment");
		StructDelete(loc.imageTagArgs, "attachmentStyle");

		if (IsJson(arguments.attachment))
			arguments.attachment = DeserializeJson(arguments.attachment);

		// Handle attachment images
		if (IsStruct(arguments.attachment))
		{
			// ugly fix due to the fact that id can't be passed along to cfinvoke
			if (StructKeyExists(loc.imageTagArgs, "id"))
			{
				loc.imageTagArgs.wheelsId = loc.imageTagArgs.id;
				StructDelete(loc.imageTagArgs, "id");
			}

			if (Len(arguments.attachmentStyle))
				loc.imageTagArgs.src = arguments.attachment.styles[arguments.attachmentStyle].url;
			else
				loc.imageTagArgs.src = arguments.attachment.url;

			if (!StructKeyExists(loc.imageTagArgs, "alt"))
				loc.imageTagArgs.alt = capitalize(ReplaceList(SpanExcluding(Reverse(SpanExcluding(Reverse(loc.imageTagArgs.src), "/")), "."), "-,_", " , "));

			loc.returnValue = $tag(name="img", skip="source,key,category", close=true, attributes=loc.imageTagArgs);

			// ugly fix continued
			if (StructKeyExists(loc.imageTagArgs, "wheelsId"))
				loc.returnValue = ReplaceNoCase(loc.returnValue, "wheelsId", "id");
		}
		// Normal `imageTag()` request
		else
		{
			loc.returnValue = loc.coreImageTag(loc.imageTagArgs);
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>
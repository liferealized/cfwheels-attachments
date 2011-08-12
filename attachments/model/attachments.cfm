<!---
	method to use in your models init() to specify that a model property
	will allow for file uploads and processing of images
--->
<cffunction name="hasAttachment" access="public" output="false" returntype="void" mixin="model">
	<cfargument name="property" type="string" required="true" hint="Name of property on the model to store JSON data related to the attached file." />
	<cfargument name="url" type="string" required="false" default="/files/attachments/:model/:property/:id/:style/:filename" hint="Format in which to reference the file as a URL. Use placeholders for `:model`, `:property`, `:id`, `:style`, and `:filename`." />
	<cfargument name="path" type="string" required="false" default="/files/attachments/:model/:property/:id/:style/:filename" hint="Format in which to store the file in storage. Use placeholders for `:model`, `:property`, `:id`, `:style`, and `:filename`." />
	<cfargument name="styles" type="string" required="false" default="" hint="You may pass in multiple styles. The syntax is `nameOfStyle:widthxheight>`. An actual example would be `small:150x150>,medium:300x300>`. The greater than sign at the end means that the attchments plugin should keep the aspect ratio of the photo uploaded. Styles will only be run on images that your ColdFusion server can do processing on." />
	<cfargument name="storage" type="string" required="false" default="filesystem" hint="Other options include `s3` and `filesystem,s3`." />
	<cfargument name="blockExtensions" type="string" required="false" default="cfm,cfml,cfc,dbm,jsp,asp,aspx,exe,php,cgi,shtml" hint="List of file extensions to not allow. This is the default behavior unless overridden by `allowExtensions`. If `allowExtensions` is set, this argument is then ignored." />
	<cfargument name="allowExtensions" type="string" required="false" default="" hint="List of file extensions to allow. If this is set, the `blockExtensions` argument is ignored." />
	<cfscript>
		var loc = {};
		
		// set variables.wheels.class.attachments if it does not exist
		if (!StructKeyExists(variables.wheels.class, "attachments"))
			variables.wheels.class.attachments = {};
				
		loc.styles = ListToArray(arguments.styles, ",", false);
		arguments.styles = {};
		
		// do processing on the styles to set them up for later
		// we do this now so we only do it once for each `hasAttachment()` call
		if (ArrayLen(loc.styles))
		{	
			for (loc.style in loc.styles)
			{
				loc.name = ListFirst(loc.style, ":");
				loc.width = ListFirst(ListLast(loc.style, ":"), "x");
				loc.height = ListLast(Replace(ListLast(loc.style, ":"), ">", "", "all"), "x");
				loc.preserveAspect = Find(">", loc.style) gt 0;
				
				arguments.styles[loc.name] = {
					  width = loc.width
					, height = loc.height
					, preserveAspect = loc.preserveAspect
				};
			}
		}
		
		// set this attachment
		variables.wheels.class.attachments[arguments.property] = Duplicate(arguments);
		
		// allow for the two new types of callbacks
		if (!StructKeyExists(variables.wheels.class.callbacks, "beforePostProcessing"))
			variables.wheels.class.callbacks.beforePostProcessing = [];
		
		if (!StructKeyExists(variables.wheels.class.callbacks, "afterPostProcessing"))
			variables.wheels.class.callbacks.afterPostProcessing = [];
		
		// set callbacks for this property
		afterDelete(method="$deleteAttachments");
		afterCreate(method="$saveAttachments");
		beforeValidationOnUpdate(method="$saveAttachments");
		jsonProperty(property=arguments.property, type="struct");
	</cfscript>
</cffunction>
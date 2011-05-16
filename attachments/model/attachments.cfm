<!---
	method to use in your models init() to specify that a model property
	will allow for file uploads and processing of images
--->
<cffunction name="hasAttachment" access="public" output="false" returntype="void" mixin="model">
	<cfargument name="property" type="string" required="true" />
	<cfargument name="url" type="string" required="false" default="/files/attachments/:model/:property/:id/:style/:filename" />
	<cfargument name="path" type="string" required="false" default="/files/attachments/:model/:property/:id/:style/:filename" />
	<cfargument name="styles" type="string" required="false" default="" hint="NOT IMPLEMENTED YET. You may pass in multiple styles. The syntax is `nameOfStyle:widthxheight>`. An actual example would be `small:150x150>,medium:300x300>`. The greater than sign at the end means that the attchments plugin should keep the aspect ratio of the photo uploaded. Styles will only be run on images that you coldfusion server can do processing on." />
	<cfargument name="storage" type="string" required="false" default="filesystem" hint="Other options include `s3` and `filesystem,s3`." />
	<cfscript>
		var loc = {};
		
		// set variables.wheels.class.attachments if it does not exist
		if (!StructKeyExists(variables.wheels.class, "attachments"))
			variables.wheels.class.attachments = {};
				
		loc.styles = ListToArray(arguments.styles, ",", false);
		arguments.styles = {};
		
		// do processing on the styles to set them up for later
		// we do this now so we only do it once for each hasAttachment() call
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
		
		//set this attachment
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

<cffunction name="$saveAttachments" access="public" output="false" returntype="boolean">
	<cfscript>
		var loc = { success = true };
		
		if (!FindNoCase("multipart", cgi.content_type))
			return false;
			
		if (!StructKeyExists(variables.wheels.instance, "attachmentsSaved"))
		{
			if (!StructKeyExists(variables, "$persistedProperties") || !StructKeyExists(variables.$persistedProperties, ListFirst(primaryKey())))
				$updatePersistedProperties();
			
			// loop over our attachements and upload each one
			for (loc.attachment in variables.wheels.class.attachments)
			{
				loc.saved = $saveAttachment(property=loc.attachment);
				
				if (loc.success)
					loc.success = loc.saved;
			}
			
			variables.wheels.instance.attachmentsSaved = true;
			
			if (loc.success)
			{
				this.save();
				this.reload();
			}
		}
	</cfscript>
	<cfreturn loc.success />
</cffunction>

<cffunction name="$saveAttachment" access="public" output="false" returntype="boolean">
	<cfargument name="property" type="string" required="true" />
	<cfscript>
		var loc = { badExtensions = "cfm,cfml,cfc,dbm,jsp,asp,aspx,exe,php,cgi,shtml" };
		
		loc.attachment = variables.wheels.class.attachments[arguments.property];
		
		// only try to upload something if we have the proper $attachment field
		if (StructKeyExists(this, loc.attachment.property & "$attachment"))
		{
			loc.file = $saveFileToTempDirectory(argumentCollection=arguments);
			loc.filePath = Replace(GetTempDirectory() & loc.file.serverFile, "\", "/", "all");
			
			// check to make sure we don't have a bad file
			if (!ListFindNoCase(loc.badExtensions, loc.file.serverFileExt))
			{
				this[loc.attachment.property] = $saveFileToStorage(source = loc.filePath, argumentCollection = loc.attachment);
				
				if (IsImageFile(loc.filePath) && StructCount(loc.attachment.styles))
				{
					// not implemented
					for (loc.style in loc.attachment.styles)
						this[loc.attachment.property].styles[loc.style] = $saveImageFileWithStyle(source = loc.filePath, argumentCollection = loc.attachment, style = loc.style);
				}
			}
			else
			{
				$file(action = "delete", file = loc.filePath);
				return false;
			}
		}		
	</cfscript>
	<cfreturn true />
</cffunction>

<cffunction name="$saveImageFileWithStyle" access="public" output="false" returntype="struct">
	<!--- TBD --->
</cffunction>

<cffunction name="$saveFileToTempDirectory" access="public" output="false" returntype="struct">
	<cfargument name="property" type="string" required="true" />
	<cfscript>
		// set the file in a temp location to verify it's not evil
		var fileArgs = {
			  action = "upload"
			, fileField = this[arguments.property & "$attachment"]
			, destination = GetTempDirectory()
			, result = "returnValue"
			, nameconflict = "overwrite"
		};
	</cfscript>
	<cfreturn $file(argumentCollection=fileArgs) />
</cffunction>

<cffunction name="$saveFileToStorage" access="public" output="false" returntype="struct">
	<cfargument name="source" type="string" required="true" />
	<cfargument name="property" type="string" required="true" />
	<cfargument name="url" type="string" required="true" />
	<cfargument name="path" type="string" required="true" />
	<cfargument name="storage" type="string" required="true" />
	<cfscript>
		var loc = {};
		
		arguments.fileName = ListLast(arguments.source, "/");
		arguments.path = $createAttachmentPath(argumentCollection=arguments);
		arguments.url = $createAttachmentPath(argumentCollection=arguments);
		arguments.storage = ListToArray(ReplaceList(arguments.storage, "filesystem,s3", "FileSystem,S3"));
		
		for (loc.storageType in arguments.storage)
		{
			if (!StructKeyExists(request, "storage") || !StructKeyExists(request.storage, loc.storageType))
				request.storage[loc.storageType] = $createObjectFromRoot(
					  path = "plugins.attachments.storage"
					, fileName = loc.storageType
					, method = "init");
				
			request.storage[loc.storageType].write(source=arguments.source, path=arguments.path);
		}
		
		StructDelete(arguments, "source", false);
	</cfscript>
	<cfreturn arguments />
</cffunction>

<cffunction name="$createAttachmentPath" access="public" output="false" returntype="string">
	<cfargument name="path" type="string" required="true" />
	<cfargument name="fileName" type="string" required="true" />
	<cfargument name="property" type="string" required="true" />
	<cfargument name="style" type="string" required="false" default="" />
	<cfscript>
		arguments.path = ReplaceNoCase(arguments.path, ":id", this.id, "one");
		
		if (!Len(arguments.style))
			arguments.path = ReplaceNoCase(arguments.path, "/:style", "", "one");
		else
			arguments.path = ReplaceNoCase(arguments.path, ":style", arguments.style, "one");
		
		arguments.path = ReplaceNoCase(arguments.path, ":filename", arguments.fileName, "one");
		arguments.path = ReplaceNoCase(arguments.path, ":model", variables.wheels.class.modelName, "one");
		arguments.path = ReplaceNoCase(arguments.path, ":property", arguments.property, "one");
	</cfscript>
	<cfreturn arguments.path />
</cffunction>

<cffunction name="$deleteAttachments" access="public" output="false" returntype="boolean">
	<cfscript>
		var loc = { success=true };
		
		// loop over our attachements and upload each one
		for (loc.attachment in variables.wheels.class.attachments)
		{
			loc.deleted = $deleteAttachment(property=loc.attachment);
			
			if (loc.success)
				loc.success = loc.deleted;
		}
	</cfscript>
	<cfreturn loc.success />
</cffunction>

<cffunction name="$deleteAttachment" access="public" output="false" returntype="boolean">
	<cfargument name="property" type="string" required="true" />
	<cfscript>
		var loc = {};
		
		loc.attachment = variables.wheels.class.attachments[arguments.property];
		
		if (IsSimpleValue(this.file)) {
			this.file = DeserializeJson(this.file);
		}
		loc.filePath = Replace(this.file.path, "\", "/", "all");
		
		this[loc.attachment.property] = $deleteFileFromStorage(source = loc.filePath, argumentCollection = loc.attachment);
	</cfscript>
	<cfreturn true />
</cffunction>

<cffunction name="$deleteFileFromStorage" access="public" output="false" returntype="struct">
	<cfargument name="source" type="string" required="true" />
	<cfargument name="property" type="string" required="true" />
	<cfargument name="url" type="string" required="true" />
	<cfargument name="path" type="string" required="true" />
	<cfargument name="storage" type="string" required="true" />
	<cfscript>
		var loc = {};
		
		arguments.fileName = ListLast(arguments.source, "/");
		arguments.path = $createAttachmentPath(argumentCollection=arguments);
		arguments.url = $createAttachmentPath(argumentCollection=arguments);
		arguments.storage = ListToArray(ReplaceList(arguments.storage, "filesystem,s3", "FileSystem,S3"));
		
		for (loc.storageType in arguments.storage)
		{
			if (!StructKeyExists(request, "storage") || !StructKeyExists(request.storage, loc.storageType))
				request.storage[loc.storageType] = $createObjectFromRoot(
					  path = "plugins.attachments.storage"
					, fileName = loc.storageType
					, method = "init");
			
			loc.pathListLen = ListLen(arguments.path, "/\");
			loc.path = "";
			for (loc.i = 1; loc.i < loc.pathListLen; loc.i++)
			{
				loc.path = ListAppend(loc.path, ListGetAt(arguments.path, loc.i, "/\"), "/");
			}
			loc.path = "/#loc.path#/";
			
			request.storage[loc.storageType].delete(path=loc.path, directory=true, recursive=true);
		}
	</cfscript>
	<cfreturn arguments />
</cffunction>
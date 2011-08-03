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
		var loc = {};
		
		loc.attachment = variables.wheels.class.attachments[arguments.property];
		
		// only try to upload something if we have the proper $attachment field
		if (StructKeyExists(this, loc.attachment.property & "$attachment"))
		{
			loc.file = $saveFileToTempDirectory(argumentCollection=arguments);
			loc.filePath = Replace(GetTempDirectory() & loc.file.ServerFile, "\", "/", "all");
			
			// check to make sure we don't have a bad file
			if ($validateAttachmentFileType(loc.file.ServerFileExt, loc.attachment.blockExtensions, loc.attachment.allowExtensions))
			{
				this[loc.attachment.property] = $saveFileToStorage(source=loc.filePath, argumentCollection=loc.attachment);
				
				if (IsImageFile(loc.filePath) && StructCount(loc.attachment.styles))
				{
					// not implemented
					for (loc.style in loc.attachment.styles)
						this[loc.attachment.property].styles[loc.style] = $saveImageFileWithStyle(source=loc.filePath, argumentCollection=loc.attachment, style=loc.style);
				}
			}
			else
			{
				$file(action="delete", file=loc.filePath);
				this.addError(property=arguments.property, message="File is not a valid type.");
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

<cffunction name="$validateAttachmentFileType" returntype="boolean" output="false" hint="Returns `true` if file extension matches `whitelist` (and `whitelist` is set). If no `whitelist` is set, returns `true` if file extension is not found in `blacklist`.">
	<cfargument name="extension" type="string" required="true" hint="File extension to validate." />
	<cfargument name="blacklist" type="string" required="false" default="" hint="Blacklist to check if no whitelist is set." />
	<cfargument name="whitelist" type="string" required="false" default="" hint="Whitelist to check if set." />
	<cfscript>
		if (Len(arguments.whitelist))
		{
			if (ListFindNoCase(arguments.whitelist, arguments.extension))
				return true;
			else
				return false;
		}
		else
		{
			if (!ListFindNoCase(arguments.blacklist, arguments.extension))
				return true;
			else
				return false;
		}
	</cfscript>
</cffunction>
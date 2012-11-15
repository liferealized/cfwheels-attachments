<cffunction name="$saveAttachments" access="public" output="false" returntype="boolean">
	<cfscript>
		var loc = { success = true };

		if (!FindNoCase("multipart", cgi.content_type))
			return false;
			
		if (!StructKeyExists(variables, "$attachmentsSaved"))
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
			
			variables.$attachmentsSaved = true;
			
			if (loc.success)
			{
				this.save();
				this.reload();
			}
		}
	</cfscript>
	<cfreturn loc.success />
</cffunction>

<cffunction name="$updateAttachments" access="public" output="false" returntype="boolean">
	<cfscript>
		var loc = { success = true };

		if (!FindNoCase("multipart", cgi.content_type))
			return false;
			
		if (!StructKeyExists(variables, "$attachmentsSaved"))
		{
			if (!StructKeyExists(variables, "$persistedProperties") || !StructKeyExists(variables.$persistedProperties, ListFirst(primaryKey())))
				$updatePersistedProperties();

			// loop over our attachements and upload each one
			for (loc.attachment in variables.wheels.class.attachments)
			{
				if (StructKeyExists(this, loc.attachment & "$attachment") && Len(form[this[loc.attachment & "$attachment"]]))
				{
					loc.attempted = true;
					this[loc.attachment & "_old"] = this.changedFrom(loc.attachment);
					$deleteAttachment(loc.attachment & "_old", variables.wheels.class.attachments[loc.attachment]);
					loc.saved = $saveAttachment(loc.attachment);
				}
				else
				{
					loc.attempted = false;
					this[loc.attachment] = this.changedFrom(loc.attachment);
					loc.saved = false;
				}
				
				if (loc.success)
					loc.success = !loc.attempted || loc.saved;
			}
			
			variables.$attachmentsSaved = true;
			
			if (loc.saved)
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
				this[loc.attachment.property] = $saveFileToStorage(
					  argumentCollection=loc.attachment
					, source=loc.filePath
					, fileSize=loc.file.FileSize);
	
				if (IsImageFile(loc.filePath) && StructCount(loc.attachment.styles))
				{
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
	<cfargument name="source" type="string" required="true" hint="Source of original image to resize." />
	<cfargument name="style" type="string" required="true" hint="Name of style to save." />
	<cfscript>
		var loc = {};
		loc.style = arguments.styles[arguments.style];
		loc.image = ImageRead(ExpandPath(this[arguments.property].url));
		loc.largerDimension = loc.image.height > loc.image.width ? "height" : "width";
		loc.smallerDimension = loc.largerDimension == "width" ? "height" : "width";
		loc.resizeArgs = {
			name=loc.image
		};
		
		// If image is larger than resize specifications, resize it
		if (loc.image.width > loc.style.width || loc.image.height > loc.style.height)
		{
			// If we're preserving same aspect ratio
			if (loc.style.preserveAspect)
			{
				// Determine which dimension to use for resize
				// Note: `ImageScaleToFit` doesn't accept an `argumentCollection` on Railo 3.3, so we need to decide with an `if` block
				if (loc.largerDimension == "width")
					ImageScaleToFit(loc.image, loc.style[loc.largerDimension], "");
				else
					ImageScaleToFit(loc.image, "", loc.style[loc.largerDimension]);
			}
			// If we're not preserving same aspect ratio
			else
			{
				// Determine which dimension to use for resize
				// Note: See note above about `ImageScaleToFit`
				if (loc.smallerDimension == "width")
					ImageScaleToFit(loc.image, loc.style[loc.smallerDimension], "");
				else
					ImageScaleToFit(loc.image, "", loc.style[loc.smallerDimension]);
				
				// Crop excess
				loc.newWidth = loc.image.width < loc.style.width ? loc.image.width : loc.style.width;
				loc.newHeight = loc.image.height < loc.style.height ? loc.image.height : loc.style.height;
				ImageCrop(loc.image, 0, 0, loc.newWidth, loc.newHeight);
			}
		}
		
		// Build path for style file and write file
		return $saveImageToStorage(
			  argumentCollection=arguments
			, image=loc.image
			, style=arguments.style);
	</cfscript>
</cffunction>

<cffunction name="$saveFileToTempDirectory" access="public" output="false" returntype="struct">
	<cfargument name="property" type="string" required="true" />
	<cfscript>
		// Set the file in a temp location to verify it's not evil
		var fileArgs = {
			  action = "upload"
			, fileField = this[arguments.property & "$attachment"]
			, destination = GetTempDirectory()
			, result = "returnValue"
			, nameconflict = "overwrite"
		};

		try
		{
			return $file(argumentCollection=fileArgs);
		}
		catch (any e)
		{
			// This is only tested on CF9. If you get an error on Railo, see if there is an equivalent error to
			//   catch in another `catch` block.
			if (e.Detail contains "zero-length")
			{
				this.addError(property=arguments.property, message="Can't upload an empty file");
				return false;
			}
			else
			{
				$throw(argumentCollection=e);
			}
		}
	</cfscript>
</cffunction>

<cffunction name="$saveFileToStorage" access="public" output="false" returntype="struct">
	<cfargument name="source" type="string" required="true" />
	<cfargument name="property" type="string" required="true" />
	<cfargument name="url" type="string" required="true" />
	<cfargument name="path" type="string" required="true" />
	<cfargument name="storage" type="string" required="true" />
	<cfargument name="fileSize" type="numeric" required="true" />
	<cfscript>
		var loc = {};
		
		arguments.fileName = ListLast(arguments.source, "/");
		arguments.path = $createAttachmentPath(argumentCollection=arguments);
		arguments.url = $createAttachmentPath(argumentCollection=arguments);
		arguments.storage = ListToArray(ReplaceList(arguments.storage, "filesystem,s3", "FileSystem,S3"));
		arguments.fileSize = arguments.fileSize;
		
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
		StructDelete(arguments, "allowExtensions");
		StructDelete(arguments, "blockExtensions");
	</cfscript>
	<cfreturn arguments />
</cffunction>

<cffunction name="$saveImageToStorage" access="public" output="false" returntype="struct">
	<cfargument name="image" required="true" hint="Image object to save." />
	<cfargument name="property" type="string" required="true" hint="Property to store metadata to." />
	<cfargument name="url" type="string" required="true" hint="URL pattern." />
	<cfargument name="path" type="string" required="true" hint="Path pattern." />
	<cfargument name="storage" type="string" required="true" hint="Storage." />
	<cfargument name="style" type="string" required="true" hint="Style name." />
	<cfscript>
		var loc = {};
		
		arguments.fileName = ListLast(arguments.image.source, "/\");
		arguments.path = $createAttachmentPath(argumentCollection=arguments);
		arguments.url = $createAttachmentPath(argumentCollection=arguments);
		arguments.storage = ListToArray(ReplaceList(arguments.storage, "filesystem,s3", "FileSystem,S3"));
		arguments.source = GetTempDirectory() & arguments.fileName;
		
		ImageWrite(arguments.image, arguments.source);
		
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
		StructDelete(arguments, "allowExtensions");
		StructDelete(arguments, "blockExtensions");
		StructDelete(arguments, "image");
		StructDelete(arguments, "styles");
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
		
		// loop over our attachments and delete each one
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
	<cfargument name="property" type="string" required="true" hint="Name of property to reference for file deletion." />
	<cfargument name="attachmentConfig" type="struct" required="false" default="#variables.wheels.class.attachments[arguments.property]#" hint="Attachment config to reference." />
	<cfscript>
		var loc = {};
		
		if (IsSimpleValue(this[arguments.property]) && IsJson(this[arguments.property]))
			this[arguments.property] = DeserializeJson(this[arguments.property]);

		if (StructKeyExists(this[arguments.property], "path")) {
			loc.filePath = Replace(this[arguments.property].path, "\", "/", "all");
		
			this[arguments.attachmentConfig.property] = $deleteFileFromStorage(source=loc.filePath, argumentCollection=arguments.attachmentConfig);
		}
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
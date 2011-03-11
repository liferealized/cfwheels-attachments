<!--- storage settings --->
<cfset loc.nameConflict = "overwrite" />

<!--- put your s3 settings here including the bucketName, accessKey and secretKey --->
<cfset loc.bucketName = "your-bucket-name" />
<cfset loc.accessKey = "your-access-key" />
<cfset loc.secretKey = "your-secret-key" />
<cfset loc.acl = [ { group = "all", permission = "read" } ] />
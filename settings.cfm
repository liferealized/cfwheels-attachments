<!--- storage settings --->
<cfset loc.nameConflict = "overwrite" />

<!--- put your s3 settings here including the bucketName, accessKey and secretKey --->
<cfset loc.bucketName = "reservoir-backup" />
<cfset loc.accessKey = "AKIAJLYSEXXHTNM4LGHA" />
<cfset loc.secretKey = "xUWxOPaQw+uvae6BPu6EyrEhqsfK0VUdQy4fhUyy" />
<cfset loc.acl = [ { group = "all", permission = "read" } ] />
<cfsetting enablecfoutputonly="true" />

<cfset attachments = {}>
<cfset attachments.version = "0.7">

<cfinclude template="stylesheets/doc_styles.cfm" />

<cfoutput>

<h1>Attachments v#attachments.version#</h1>

<p>
	Add support for file uploads to your model with the <tt>hasAttachment()</tt> function. Also provides <tt>attachmentImageTag()</tt> and <tt>attachmentLinkTo()</tt> view helpers.
</p>
<p>
	Automatically resize uploaded images to a set of &quot;styles&quot; that you define. (For example, you could automatically
	resize for thumbnail, small, medium, large, etc.)
</p>
<p>
	Overrides <tt><a href="http://cfwheels.org/docs/function/filefield">fileField()</a></tt> to work better with <tt>&lt;cffile&gt;</tt>
	and <a href="http://cfwheels.org/docs/chapter/nested-properties">nested properties</a>.
</p>

<h2>Dependencies</h2>
<p>You must also install the JSON Properties plugin for the Attachments plugin to work.</p>

<h2>Usage</h2>

<h3>Model Configuration</h3>
<p>
	Call the included <tt>hasAttachment()</tt> from a model's <tt>init()</tt> method to bind one or more properties to handle uploaded
	files.
</p>
<p>
	The plugin stores data about the uploaded files as serialized JSON data in your model, so you should set the configured property's
	corresponding database column to a type of <tt>TEXT</tt> or similar.
</p>

<h4><tt>hasAttachment()</tt> Arguments</h4>
<table>
	<thead>
		<tr>
			<th>Argument</th>
			<th>Type</th>
			<th>Required</th>
			<th>Default</th>
			<th>Description</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><tt>property</tt></td>
			<td>string</td>
			<td><tt>true</tt></td>
			<td></td>
			<td>Name of property on the model to store JSON data related to the attached file.</td>
		</tr>
		<tr class="highlight">
			<td><tt>url</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>/files/attachments/:model/<br />:property/:id/:style/:filename</tt></td>
			<td>Format in which to reference the file as a URL. Use placeholders for <tt>:model</tt>, <tt>:property</tt>, <tt>:id</tt>, <tt>:style</tt>, and <tt>:filename</tt>.</td>
		</tr>
		<tr>
			<td><tt>path</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>/files/attachments/:model/<br />:property/:id/:style/:filename</tt></td>
			<td>Format in which to store the file in storage. Use placeholders for <tt>:model</tt>, <tt>:property</tt>, <tt>:id</tt>, <tt>:style</tt>, and <tt>:filename</tt>.</td>
		</tr>
		<tr class="highlight">
			<td><tt>styles</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>[empty string]</tt></td>
			<td>You may pass in multiple styles. The syntax is <tt>nameOfStyle:widthxheight&gt;</tt>. An actual example would be <tt>small:150x150&gt;,medium:300x300></tt>. The greater than sign at the end means that the attchments plugin should keep the aspect ratio of the photo uploaded. Styles will only be run on images that your ColdFusion server can do processing on.</td>
		</tr>
		<tr>
			<td><tt>storage</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>filesystem</tt></td>
			<td>Other options include <tt>s3</tt> and <tt>filesystem,s3</tt></td>
		</tr>
		<tr class="highlight">
			<td><tt>blockExtensions</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>cfm,cfml,cfc,dbm,jsp,asp,<br />aspx,exe,php,cgi,shtml</tt></td>
			<td>List of file extensions to not allow. This is the default behavior unless overridden by <tt>allowExtensions</tt>. If <tt>allowExtensions</tt> is set, this argument is then ignored.</td>
		</tr>
		<tr>
			<td><tt>allowExtensions</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>[empty string]</tt></td>
			<td>List of file extensions to allow. If this is set, the <tt>blockExtensions</tt> argument is ignored.</td>
		</tr>
	</tbody>
</table>

<h4>Callbacks</h4>
<p>
	This plugin adds its own callbacks to the model's callback chain.
</p>
<ul>
	<li>
		<tt><a href="http://cfwheels.org/docs/function/aftercreate">afterCreate</a></tt>:
		Save attachment info to database and files to file system(s).
	</li>
	<li>
		<tt><a href="http://cfwheels.org/docs/function/beforevalidationonupdate">beforeValidationOnUpdate</a></tt>:
		Save attachment info to database and files to file system(s).
	</li>
	<li>
		<tt><a href="http://cfwheels.org/docs/function/afterdelete">afterDelete</a></tt>: Delete attachment files.
	</li>
</ul>
<p>
	Most of the time, this will not matter to you, but if you want for the model to do additional processing on the data after
	the plugin has done its job, you will want to add your own callback chains using
	<tt><a href="http://cfwheels.org/docs/function/afterCreate">afterCreate</a></tt> and
	<tt><a href="http://cfwheels.org/docs/function/afterUpdate">afterUpdate</a></tt>.
</p>

<h4>Examples</h4>

<h5>Example 1: Simple configuration</h5>
<p>
	In its most simple form, let's pretend that you want to save files to a property in the <tt>comment</tt> model called <tt>attachment</tt>:
</p>
<pre>
&lt;--- models/Comment.cfc ---&gt;
&lt;cfcomponent extends=&quot;Model&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;!--- The `attachment` column should be of type `TEXT` ---&gt;
		&lt;cfset hasAttachment(&quot;attachment&quot;)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</pre>
<p>
	In your form, you can use the <tt>fileField()</tt> helper to allow users to upload the attachment, and the
	plugin will take care of the rest.
</p>
<pre>
&lt;cfoutput&gt;
	##startFormTag(action=&quot;create&quot;, multipart=true)##
		##fileField(label=&quot;Upload an Attachment&quot;, objectName=&quot;comment&quot;, property=&quot;attachment&quot;)##
		##submitTag(value=&quot;Upload&quot;)##
	##endFormTag()##
&lt;/cfoutput&gt;</pre>
<p>
	On your application's file system, the file will be saved to
	<tt>/files/attachments/comment/attachment/197/my_spreadsheet.xlsx</tt> (assuming that the record gets assigned an <tt>id</tt>
	of <tt>197</tt> and that the file uploaded by the user is named <tt>my_spreadsheet.xlsx</tt>). You will then be able to reference
	data about the uploaded file in the <tt>attachment</tt> property.
</p>
<pre>
&lt;--- controllers/Comments.cfc ---&gt;
&lt;cfcomponent extends=&quot;Controller&quot;&gt;
	&lt;cffunction name=&quot;view&quot;&gt;
		&lt;cfset comment = model(&quot;comment&quot;).findByKey(197)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;

&lt;--- views/comments/view.cfm ---&gt;
&lt;cfoutput&gt;
	&lt;p&gt;&lt;a href=&quot;##comment.attachment.url##&quot;&gt;Download the File&lt;/a&gt;&lt;/p&gt;
&lt;/cfoutput&gt;</pre>

<h5>Example 2: Saving to a different location</h5>
<p>
	If you want to store the file in a different location on the server, you can specify the path using the <tt>:path</tt>
	argument and the placeholders for <tt>:model</tt>, <tt>:property</tt>, <tt>:id</tt>, <tt>:style</tt> (more on this
	later), and <tt>:filename</tt>. Note that the <tt>:style</tt> part of the path is only used if you define image
	styles using the <tt>styles</tt> argument.
</p>
<pre>
&lt;--- models/Comment.cfc ---&gt;
&lt;cfcomponent extends=&quot;Model&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;!--- The `attachment` column should be of type `TEXT` ---&gt;
		&lt;cfset hasAttachment(property=&quot;attachment&quot;, path=&quot;/files/uploads/:model/:property/:id/:style/:filename&quot;)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</pre>
<p>
	If your server is configured to serve files from different URL than the default, you can also specify that with the <tt>url</tt> argument.
</p>
<pre>
&lt;--- models/Comment.cfc ---&gt;
&lt;cfcomponent extends=&quot;Model&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;cfset hasAttachment(property=&quot;attachment&quot;, path=&quot;/files/uploads/:model/:property/:id/:style/:filename&quot;, url=&quot;http://media.example.com/:model/:property/:id/:style/:filename&quot;)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</pre>

<h5>Example 3: Styles for images</h5>
<p>
	The attachments plugin will also handle the creation of &quot;styles&quot; for image files uploaded to your model.
	If you choose, you can create any named style that you would like (for example, <tt>thumbnail</tt>).
</p>
<p>
	Let's say that we want to create 2 image styles: a <tt>thumbnail</tt> style at 50 x 50 pixels and a
	<tt>medium</tt> style at 250 x 250 pixels. You would use the <tt>styles</tt> argument like so:
</p>
<pre>
&lt;--- models/Profile.cfc ---&gt;
&lt;cfcomponent extends=&quot;Model&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;cfset hasAttachment(property=&quot;avatar&quot;, styles=&quot;medium:250x250,thumbnail:50x50&quot;)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</pre>
<p>
	Now when the user uploads an image file supported by your CFML engine and your model passes validation, the
	Attachments plugin will resize the image into those dimensions (and crop off any excess).
</p>
<p>
	If you'd rather keep an image's aspect ratio the same and define a set of boundaries for the image,
	you can add a <tt>&gt;</tt> character to the end of any of the styles.
</p>
<pre>
&lt;--- models/Profile.cfc ---&gt;
&lt;cfcomponent extends=&quot;Model&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;cfset hasAttachment(property=&quot;avatar&quot;, styles=&quot;medium:250x250&gt;,thumbnail:50x50&quot;)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</pre>
<p>
	With the styles defined above, let's say that the user uploads an image called <tt>Vacation-in-Switzerland.jpg</tt>
	that is 400 by 300 pixels. The resulting file structure will look like this after the Attachments plugin does its
	magic:
</p>
<ul>
	<li>
		<tt>/files/attachments/profile/avatar/423/medium/Vacation-in-Switzerland.jpg</tt> --&gt; 250 x 188 pixels
		(long edge resized to 250 pixels, short edge resized proportionately)
	</li>
	<li>
		<tt>/files/attachments/profile/avatar/423/thumbnail/Vacation-in-Switzerland.jpg</tt> --&gt; 50 x 50 pixels
		(height is set to 50 pixels, width is cropped at 50 pixels)
	</li>
	<li>
		<tt>/files/attachments/profile/avatar/423/Vacation-in-Switzerland.jpg</tt> --&gt; 400 x 300 pixels (original dimensions)
	</li>
</ul>

<h5>Example 4: Whitelisting files</h5>
<p>
	By default, the Attachments plugin will block a list of potentially malicious files (using a default value for the
	<tt>blockExtensions</tt> argument). But it is strongly recommended for security reasons that you define a whitelist of
	what is allowed to be uploaded instead.
</p>
<p>
	Pretending that we only wanted some Microsoft Office formats to be uploaded, we could define something like this using the
	<tt>allowExtensions</tt> argument:
</p>
<pre>
&lt;--- models/Comment.cfc ---&gt;
&lt;cfcomponent extends=&quot;Model&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;cfset hasAttachment(property=&quot;attachment&quot;, allowExtensions=&quot;doc,docx,xls,xlsx,ppt,pptx,mdb&quot;)&gt;
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</pre>
<p>
	Note that when the <tt>allowExtensions</tt> list is provided, the <tt>blockExtensions</tt> list will be ignored completely.
</p>

<h3>View Helpers</h3>
<p>
	The plugin also provides helpers&mdash;<tt>attachmentImageTag()</tt> and <tt>attachmentLinkTo()</tt>&mdash;for displaying
	images and linking to files uploaded via attachments.
</p>

<h3>Displaying Images via <tt>attachmentImageTag()</tt></h3>
<p>
	<tt>attachmentImageTag()</tt> allows you to display an image uploaded via the Attachments plugin. It optionally allows you
	to specify any style generated when the attachment was uploaded and handles all of the data references for you.
</p>
<table>
	<thead>
		<tr>
			<th>Argument</th>
			<th>Type</th>
			<th>Required</th>
			<th>Default</th>
			<th>Description</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><tt>attachment</tt></td>
			<td>string/struct</td>
			<td><tt>false</tt></td>
			<td><tt>[empty&nbsp;string]</tt></td>
			<td>Value of attachment property. Accepts both JSON- and struct-formatted data.</td>
		</tr>
		<tr class="highlight">
			<td><tt>attachmentStyle</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>[empty&nbsp;string]</tt></td>
			<td>Name of image style to reference (as configured in <tt>hasAttachment()</tt>'s <tt>styles</tt> argument.</td>
		</tr>
	</tbody>
</table>

<h4>Examples</h4>

<h5>Example 1: Simple image call</h5>
<p>Given that there is an attachment property called <tt>attachment</tt> on the <tt>user</tt> model:</p>
<pre>
// In the `init()` method of `models/User.cfc`
hasAttachment(property="attachment", allowExtensions=GetReadableImageFormats());</pre>
<p>
	You can display uploaded images like so:
</p>
<pre>
&lt;cfoutput&gt;
	##attachmentImageTag(attachment=user.attachment)##
&lt;/cfoutput&gt;</pre>

<h5>Example 2: Display stylized image</h5>
<p>
	Given that there is an attachment property called <tt>avatar</tt> on the <tt>profile</tt> model with a style called
	<tt>small</tt>:
</p>
<pre>
// In the `init()` method of `models/Profile.cfc`
##hasAttachment(property=&quot;avatar&quot;, styles=&quot;small:100x100&quot;, allowExtensions=GetReadableImageFormats())##</pre>
<p>
	You can display the stylized image like so:
</p>
<pre>
&lt;cfoutput&gt;
	##attachmentImageTag(attachment=profile.avatar, attachmentStyle=&quot;small&quot;)##
&lt;/cfoutput&gt;</pre>

<h3>Linking to Files via <tt>attachmentLinkTo()</tt></h3>
<p>
	Similar to <tt>attachmentImageTag()</tt>, <tt>attachmentLinkTo()</tt> allows you to link to a file uploaded via this
	plugin, also optionally with image styles.
</p>
<table>
	<thead>
		<tr>
			<th>Argument</th>
			<th>Type</th>
			<th>Required</th>
			<th>Default</th>
			<th>Description</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><tt>text</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>[empty&nbsp;string]</tt></td>
			<td>Link text. If left blank, the path to the attachment file is used as the link text.</td>
		</tr>
		<tr class="highlight">
			<td><tt>attachment</tt></td>
			<td>string/struct</td>
			<td><tt>false</tt></td>
			<td><tt>[empty&nbsp;string]</tt></td>
			<td>Value of attachment property. Accepts both JSON- and struct-formatted data.</td>
		</tr>
		<tr>
			<td><tt>attachmentStyle</tt></td>
			<td>string</td>
			<td><tt>false</tt></td>
			<td><tt>[empty&nbsp;string]</tt></td>
			<td>Name of image style to reference (as configured in <tt>hasAttachment()</tt>'s <tt>styles</tt> argument.</td>
		</tr>
	</tbody>
</table>

<h4>Examples</h4>

<h5>Example 1: Simple link</h5>
<p>Given that there is an attachment property called <tt>documentation</tt> on the <tt>equipment</tt> model:</p>
<pre>
// In the `init()` method of `models/Equipment.cfc`
##hasAttachment(property=&quot;documentation&quot;)##</pre>
<p>
	You can link to the file in your view like this:
</p>
<pre>
&lt;cfoutput&gt;
	##attachmentLinkTo(text=&quot;Download the Manual&quot;, attachment=equipment.documentation)##
&lt;/cfoutput&gt;</pre>

<h5>Example 2: Link directly to a stylized image</h5>
<p>
	Given that there is an attachment property called <tt>photo</tt> on the <tt>person</tt> model with a style of
	<tt>medium</tt>:
</p>
<pre>
// In the `init()` method of `models/Person.cfc`
##hasAttachment(property=&quot;photo&quot;, styles=&quot;medium:300x300&gt;,avatar:100x100&quot;, allowExtensions=GetReadableImageFormats())##</pre>
<p>
	You can link to the stylized image in your view like so:
</p>
<pre>
&lt;cfoutput&gt;
	##attachmentLinkTo(text=&quot;Download Photo&quot;, attachment=person.photo, attachmentStyle=&quot;medium&quot;)##
&lt;/cfoutput&gt;</pre>

<h2>Uninstallation</h2>
<p>To uninstall this plugin, simply delete the <tt>/plugins/Attachments-#attachments.version#.zip</tt> file.</p>

<h2>Credits</h2>
<p>
	This plugin was created by <a href="http://iamjamesgibson.com/">James Gibson</a> and
	<a href="http://www.clearcrystalmedia.com/pm/">Chris Peters</a> with support from
	<a href="http://www.liquifusion.com/">Liquifusion Studios</a>.
</p>

</cfoutput>

<cfsetting enablecfoutputonly="false" />
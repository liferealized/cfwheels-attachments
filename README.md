# CFWheels Attachments Plugin

Add support for file uploads to your [CFWheels][1] model with the `hasAttachment()` function. Also provides `attachmentImageTag()` and `attachmentLinkTo()` view helpers.

Automatically resize uploaded images to a set of "styles" that you define. (For example, you could automatically resize for `thumbnail`, `small`, `medium`, `large`, etc.)

Overrides `fileField()` to work better with `<cffile>` and [nested properties][2].

## Dependencies

You must also install the [JSON Properties plugin][3] for the Attachments plugin to work.

## Documentation

For more documentation, install the Attachments plugin and click the _Attachments_ link in the _Plugins_ section of the debugging section of your CFWheels application's footer.

## Credits

This plugin was created by [James Gibson][4] and [Chris Peters][5] with support from [Liquifusion Studios][6].

[1]: http://cfwheels.org/
[2]: http://cfwheels.org/docs/chapter/nested-properties
[3]: https://github.com/liferealized/cfwheels-json-properties
[4]: http://iamjamesgibson.com/
[5]: http://www.clearcrystalmedia.com/
[6]: http://liquifusion.com/
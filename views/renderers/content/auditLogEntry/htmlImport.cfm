<cfscript>
	action = args.action ?: "";

	userLink  = args.userLink ?: "";
	userLabel = args.known_as ?: "";

	recordId    = args.record_id ?: "";;
	recordLabel = renderLabel( "page", recordId );
	recordLink  = event.buildAdminLink( linkTo="SiteTree.editPage", queryString="id=#recordId#" );

	message = translateResource(
		  uri  = "auditlog.htmlImport:#action#.message"
		, data = [ '<a href="#userLink#">#userLabel#</a>', '<a href="#recordLink#">#recordLabel#</a>' ]
	);
</cfscript>

<cfoutput>#message#</cfoutput>
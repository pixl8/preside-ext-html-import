<cfscript>
	action = args.action ?: "";

	userLink  = args.userLink ?: "";
	userLabel = args.known_as ?: "";

	recordId    = args.record_id ?: "";;
	recordLabel = renderLabel( "page", recordId );
	recordLink  = event.buildAdminLink( linkTo="SiteTree.editPage", queryString="id=#recordId#" );

	detail   = args.detail ?: {};
	fileName = detail.zip_file         ?: "";
	pageType = detail.child_pages_type ?: "";

	message = translateResource(
		  uri  = "auditlog.htmlImport:#action#.message"
		, data = [
			  '<a href="#userLink#">#userLabel#</a>'
			, fileName
			, translateResource( uri="page-types.#pageType#:name", defaultValue=pageType )
			, '<a href="#recordLink#">#recordLabel#</a>'
		  ]
	);
</cfscript>

<cfoutput>#message#</cfoutput>
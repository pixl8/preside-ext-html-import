component extends="preside.system.base.AdminHandler" {

	private void function extraTopRightButtonsForSiteTreeEditPage( event, rc, prc, args={} ) {
		var pageId   = prc.page.id        ?: "";
		var pageType = prc.page.page_type ?: "";

		var actions  = arguments.actions ?: [];
		var children = [];

		var allowedPageTypes = getSetting( name="htmlImport.allowedPageTypes", defaultValue=[] );

		if ( ArrayContains( allowedPageTypes, pageType ) ) {
			ArrayAppend( children, {
				  title = translateResource( "HTMLImport:action.history.title" )
				, link  = event.buildAdminLink( linkTo="auditTrail", queryString="type=htmlImport&recordId=#pageId#" )
				, icon  = "fa-history"
			} );

			if ( ArrayLen( children )) {
				ArrayInsertAt( actions, ArrayLen( actions ), {
					  title     = translateResource( "HTMLImport:action.import.title" )
					, link      = event.buildAdminLink( linkTo="HTMLImport.import", queryString="page=#pageId#" )
					, btnClass  = "btn-default"
					, iconClass = "fa-file-import"
					, children  = children
				} );
			}
		}
	}

}

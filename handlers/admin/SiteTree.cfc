component extends="preside.system.base.AdminHandler" {

	private void function extraTopRightButtonsForSiteTreeEditPage( event, rc, prc, args={} ) {
		var pageId   = prc.page.id        ?: "";
		var pageType = prc.page.page_type ?: "";

		var allowedPageTypes = getSetting( name="htmlImport.allowedPageTypes", defaultValue=[] );

		if ( ArrayContains( allowedPageTypes, pageType ) ) {
			var actions = arguments.actions ?: [];

			ArrayInsertAt( actions, ArrayLen( actions ), {
				  title     = translateResource( "HTMLImport:action.import.title" )
				, link      = event.buildAdminLink( linkTo="HTMLImport.import", queryString="page=#pageId#" )
				, iconClass = "fa-file-import"
				, btnClass  = "btn-default"
			} );
		}
	}

}

component {

	property name="pageTypesService" inject="PageTypesService";

	public string function index( event, rc, prc, args={} ) {
		var pageTypes = [];
		for ( var allowedPageType in getSetting( name="htmlImport.allowedPageTypes", defaultValue=[] ) ) {
			if ( pageTypesService.pageTypeExists( id=allowedPageType ) ) {
				ArrayAppend( pageTypes, allowedPageType );
			}
		}

		args.values = [];
		args.labels = [];

		for( var pageType in pageTypes ) {
			ArrayAppend( args.values, pageType );
			ArrayAppend( args.labels, translateResource( uri="page-types.#pageType#:name", defaultValue=pageType ) );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}

}
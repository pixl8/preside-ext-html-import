component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupFeatures( settings );
		_setupSettings( settings );
		_setupEnums( settings );
		_setupRicheditor( settings );
		_setupAssetManager( settings );
		_setupInterceptors( conf );
	}

	private void function _setupFeatures( any settings ) {
		settings.features.htmlImport = { enabled=true , siteTemplates=["*"], widgets=["*"] };
	}

	private void function _setupSettings( required settings ) {
		settings.htmlImport = settings.htmlImport ?: {};

		settings.htmlImport.allowedPageTypes = [ "standard_page" ];
	}

	private void function _setupEnums( settings ) {
		settings.enum.htmlImportPageHeading            = [ "h1", "h2", "h3", "h4", "h5", "h6" ];
		settings.enum.htmlImportChildPagesHeading      = [ "h1", "h2", "h3", "h4", "h5", "h6" ];
	}

	private void function _setupRicheditor( settings ) {
		settings.ckeditor.toolbars = settings.ckeditor.toolbars ?: {};

		StructAppend( settings.ckeditor.toolbars, { htmlImportReadOnly='Maximize,Preview' } );
	}

	private void function _setupAssetManager( required struct settings  ) {
		settings.assetmanager.folders.importHtmlFiles = {
			  label  = "Imported HTML files"
			, hidden = false
		};
	}

	private void function _setupInterceptors( conf ) {
		ArrayAppend( conf.interceptorSettings.customInterceptionPoints, "preHTMLImportPages"  );
		ArrayAppend( conf.interceptorSettings.customInterceptionPoints, "postHTMLImportPages" );
	}

}

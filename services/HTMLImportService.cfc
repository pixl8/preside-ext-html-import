/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="siteTreeService"              inject="SiteTreeService";
	property name="assetManagerService"          inject="AssetManagerService";
	property name="dynamicFindAndReplaceService" inject="DynamicFindAndReplaceService";

	variables._lib   = [];
	variables._jsoup = "";

	public any function init() {
		variables._jsoup = _new( "org.jsoup.Jsoup" );

		return this;
	}

	public string function importFromZipFile(
		  required struct  zipFile
		,          string  page              = ""
		,          string  pageHeading       = "h1"
		,          boolean childPagesEnabled = false
		,          string  childPagesHeading = "h2"
		,          string  childPagesType    = "standard_page"
		,          boolean isDraft           = false
		,          string  assetFolder       = $getPresideSetting( category="htmlimport", setting="htmlimport_asset_folder", default="importHtmlFiles" )
		,          struct  data              = {}
		,          any     logger
		,          any     progress
	) {
		var parentPageId = arguments.page;
		var totalPages = 0;

		arguments.logger?.info( "Importing HTML from ZIP..." );

		try {
			if ( !$helpers.isEmptyString( arguments.zipFile.path ?: "" ) ) {
				arguments.logger?.info( "Unpacking ZIP..." );

				var htmlFileDir = _unpackZipFile( zipFilePath=arguments.zipFile.path );
				var htmlContent = _getHtmlContent( htmlFileDir=htmlFileDir );

				if ( !$helpers.isEmptyString( htmlContent ) ) {
					arguments.logger?.info( "Parsing HTML..." );

					var html     = variables._jsoup.parse( htmlContent );
					var elements = html.body().children();

					var pages       = [];
					var pageTitle   = "";
					var pageContent = "";
					var pageChild   = false;

					var pagesHeading = [];
					if ( !$helpers.isEmptyString( arguments.pageHeading ) ) {
						ArrayAppend( pagesHeading, arguments.pageHeading );
					}

					if ( arguments.childPagesEnabled ) {
						ArrayAppend( pagesHeading, arguments.childPagesHeading );
					}

					var tagName = "";
					var tagText = "";

					for ( var element in elements ) {
						var tagName = element.tagName();
						var tagText = element.text();

						if ( ArrayFindNoCase( pagesHeading, tagName ) && !$helpers.isEmptyString( tagText ) ) {
							if ( !$helpers.isEmptyString( pageTitle ) || !$helpers.isEmptyString( pageContent ) ) {
								ArrayAppend( pages, { title=pageTitle, content=pageContent, child=pageChild } );
							}

							pageTitle   = tagText;
							pageContent = "";
							pageChild   = arguments.childPagesHeading == tagName;
						} else {
							pageContent &= element.toString();
						}
					}

					if ( !$helpers.isEmptyString( pageTitle ) || !$helpers.isEmptyString( pageContent ) ) {
						ArrayAppend( pages, { title=pageTitle, content=pageContent, child=pageChild } );
					}

					totalPages = _processPages( argumentCollection=arguments, pages=pages, htmlFileDir=htmlFileDir, parentPageId=parentPageId );
				}
			}
		} catch( any e ) {
			rethrow;
		} finally {
			try {
				DirectoryDelete( zipDir, true );
			} catch( any e ){}
		}

		if ( totalPages ) {
			arguments.logger?.info( "Total #totalPages# pages have been created." );
		} else {
			arguments.logger?.warn( "No pages have been created." );
		}

		arguments.logger?.info( "Done." );

		return parentPageId;
	}

	private string function _unpackZipFile( required string zipFilePath ) {
		var tmpDir = ExpandPath( "/uploads/tmp/#CreateUUID()#" );

		DirectoryCreate( tmpDir, true, true );

		zip action="unzip" destination=tmpDir file=arguments.zipFilePath;

		return tmpDir;
	}

	private string function _getHtmlContent( required string htmlFileDir ) {
		var htmlFiles = DirectoryList( arguments.htmlFileDir, false, "path", "*.html" );

		if ( ArrayLen( htmlFiles ) == 1 ) {
			return Trim( FileRead( htmlFiles[ 1 ] ) );
		}

		return "";
	}

	private numeric function _processPages(
		  required array   pages
		, required string  htmlFileDir
		, required string  parentPageId
		,          string  childPagesType = "standard_page"
		,          boolean isDraft        = false
		,          string  assetFolder    = $getPresideSetting( category="htmlimport", setting="htmlimport_asset_folder", default="importHtmlFiles" )
		,          struct  data           = {}
		,          any     logger
		,          any     progress
	) {
		$announceInterception( "preHTMLImportPages", { pages=arguments.pages, data=arguments.data } );

		var totalPages   = ArrayLen( arguments.pages );
		var pageTypeName = $translateResource( uri="page-types.#arguments.childPagesType#:name", defaultValue=arguments.childPagesType );

		if ( totalPages ) {
			var parentPage = siteTreeService.getPage( id=arguments.parentPageId, selectFields=[ "id", "title", "_hierarchy_slug", "page_type" ], allowDrafts=true );

			for ( var i=1; i<=totalPages; i++ ) {
				var title   = $helpers.isEmptyString( arguments.pages[ i ].title ) ? parentPage.title : arguments.pages[ i ].title;
				var content = _processImages( argumentCollection=arguments, htmlContent=arguments.pages[ i ].content );

				var slug = $helpers.slugify( title );

				if ( arguments.pages[ i ].child ) {
					var pageId = siteTreeService.getPageIdBySlug( slug="#parentPage._hierarchy_slug##slug#/" );

					if ( !$helpers.isEmptyString( pageId ) ) {
						arguments.logger?.info( "Updating #pageTypeName#: #title#" );

						siteTreeService.editPage(
							  id           = pageId
							, title        = title
							, main_content = content
							, isDraft      = arguments.isDraft
						);
					} else {
						arguments.logger?.info( "Creating #pageTypeName#: #title#" );

						pageId = siteTreeService.addPage(
							  page_type    = arguments.childPagesType
							, slug         = slug
							, parent_page  = parentPage.id
							, title        = title
							, main_content = content
							, isDraft      = arguments.isDraft
						);
					}

					arguments.pages[ i ].id = pageId;
				} else {
					arguments.logger?.info( "Updating #$translateResource( uri="page-types.#parentPage.page_type#:name", defaultValue=parentPage.page_type )#: #title#" );

					siteTreeService.editPage(
						  id           = parentPageId
						, title        = title
						, main_content = content
						, isDraft      = arguments.isDraft
					);

					arguments.pages[ i ].id = parentPageId;
				}
			}
		}

		$announceInterception( "postHTMLImportPages", { pages=arguments.pages, data=arguments.data } );

		return totalPages;
	}

	private string function _processImages(
		  required string htmlContent
		, required string htmlFileDir
		,          string assetFolder = $getPresideSetting( category="htmlimport", setting="htmlimport_asset_folder", default="importHtmlFiles" )
		,          any    logger
		,          any    progress
	) {
		return dynamicFindAndReplaceService.dynamicFindAndReplace( source=arguments.htmlContent, regexPattern='<img[^>]*src="(.*?)"[^>]*>', recurse=false, processor=function( captureGroups ) {
			var srcPath = arguments.captureGroups[ 2 ] ?: "";

			if ( !$helpers.isEmptyString( srcPath ) ) {
				var fileName = ListLast( srcPath, "/" );
				var filePath = "#htmlFileDir#/#srcPath#";

				var assetId = assetManagerService.addAsset(
					  folder            = assetFolder
					, ensureUniqueTitle = true
					, fileName          = fileName
					, filePath          = filePath
				);

				if ( !$helpers.isEmptyString( assetId ) ) {
					var configs = {
						asset = assetId
					};

					return "{{image:#UrlEncode( SerializeJSON( configs ) )#:image}}";
				}
			}

			return "";
		} );
	}

	private any function _new( className ) {
		return CreateObject( "java", arguments.className, _getLib() );
	}

	private array function _getLib() {
		if ( !ArrayLen( _lib ) ) {
			var libDir = ExpandPath( "/preside/system/services/email/lib" );

			_lib = DirectoryList( libDir, false, "path", "*.jar" );
		}
		return _lib;
	}

}
/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="siteTreeService"              inject="SiteTreeService";
	property name="assetManagerService"          inject="AssetManagerService";
	property name="dynamicFindAndReplaceService" inject="DynamicFindAndReplaceService";
	property name="htmlImportStorageProvider"    inject="HTMLImportStorageProvider";

	variables._lib   = [];
	variables._jsoup = "";

	public any function init() {
		variables._jsoup = _new( "org.jsoup.Jsoup" );

		return this;
	}

	public string function importFromZipFile(
		  required string  zipFilePath
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
		arguments.progress?.setProgress( 10 );

		try {
			if ( !$helpers.isEmptyString( arguments.zipFilePath ) ) {
				arguments.logger?.info( "Unpacking ZIP..." );

				var htmlFileDir = _unpackZipFile( zipFilePath=arguments.zipFilePath );
				var htmlContent = _getHtmlContent( htmlFileDir=htmlFileDir );

				if ( !$helpers.isEmptyString( htmlContent ) ) {
					arguments.logger?.info( "Parsing HTML..." );
					arguments.progress?.setProgress( 20 );

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

					var tagText     = "";
					var tagSelector = ArrayToList( pagesHeading, "," );

					for ( var element in elements ) {
						var tagText = element.text();
						var tagHtml = element.outerHtml();

						if ( !$helpers.isEmptyString( tagText ) && _isElementPageHeading( elementHtml=tagHtml, tagSelector=tagSelector ) ) {
							if ( !$helpers.isEmptyString( pageTitle ) || !$helpers.isEmptyString( pageContent ) ) {
								ArrayAppend( pages, { title=pageTitle, content=pageContent, child=pageChild } );
							}

							pageTitle   = tagText;
							pageContent = "";
							pageChild   = _isElementPageHeading( elementHtml=tagHtml, tagSelector=arguments.childPagesHeading );
						} else {
							pageContent &= element.toString();
						}
					}

					if ( !$helpers.isEmptyString( pageTitle ) || !$helpers.isEmptyString( pageContent ) ) {
						ArrayAppend( pages, { title=pageTitle, content=pageContent, child=pageChild } );
					}

					totalPages = _processPages( argumentCollection=arguments, pages=pages, htmlFileDir=htmlFileDir, parentPageId=parentPageId );
				} else {
					arguments.logger?.error( "No HTML file found in the ZIP." );
				}
			}
		} catch( any e ) {
			rethrow;
		} finally {
			try {
				htmlImportStorageProvider.deleteObject( path=arguments.zipFilePath, private=true );

				DirectoryDelete( zipDir, true );
			} catch( any e ){}
		}

		if ( totalPages ) {
			arguments.logger?.info( "Total #totalPages# pages have been created." );
		} else {
			arguments.logger?.warn( "No pages have been created." );
		}

		arguments.logger?.info( "Done." );
		arguments.progress?.setProgress( 100 );

		return parentPageId;
	}

	private string function _unpackZipFile( required string zipFilePath ) {
		var tmpDir = "";

		var localFilePath = htmlImportStorageProvider.getObjectLocalPath(
			  path    = arguments.zipFilePath
			, private = true
		);

		if ( FileExists( localFilePath ) ) {
			tmpDir = ExpandPath( "/uploads/tmp/#CreateUUID()#" );

			DirectoryCreate( tmpDir, true, true );

			zip action="unzip" destination=tmpDir file=localFilePath;
		}

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
				var title  = $helpers.isEmptyString( arguments.pages[ i ].title ) ? parentPage.title : arguments.pages[ i ].title;
				var slug   = $helpers.slugify( title );

				var pageId   = "";
				var pageType = "";

				if ( arguments.pages[ i ].child ) {
					pageId       = siteTreeService.getPageIdBySlug( slug="#parentPage._hierarchy_slug##slug#/" );
					pageTypeName = $translateResource( uri="page-types.#arguments.childPagesType#:name", defaultValue=arguments.childPagesType );
				} else {
					pageId       = parentPageId;
					pageTypeName = $translateResource( uri="page-types.#parentPage.page_type#:name", defaultValue=parentPage.page_type );
				}

				var content = _processImages( argumentCollection=arguments, htmlContent=arguments.pages[ i ].content, pageId=pageId );

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

				arguments.progress?.setProgress( ( ( 70 / totalPages ) * i ) + 20 );
			}
		}

		$announceInterception( "postHTMLImportPages", { pages=arguments.pages, data=arguments.data } );

		return totalPages;
	}

	private struct function _getHashes(
		  required string htmlContent
		,          any    logger
		,          any    progress
	) {
		var images  = {};
		var widgets = REMatch( "\{\{image:([^:]+):image\}\}", arguments.htmlContent );

		for ( var widget in widgets ) {
			var matched = UrlDecode( REReplace( widget, "\{\{image:([^:]+):image\}\}", "\1" ) );

			if ( IsJSON( matched ) ) {
				var config = DeserializeJSON( matched );

				if ( !$helpers.isEmptyString( config.asset ?: "" ) ) {
					var bin = assetManagerService.getAssetBinary( config.asset );

					if ( !IsNull( bin ) ) {
						StructAppend( images, { "#Hash( bin )#"=config.asset } );
					}
				}
			}
		}

		return images;
	}

	private boolean function _isElementPageHeading(
		  required string elementHtml
		, required string tagSelector
	) {
		var element         = variables._jsoup.parse( arguments.elementHtml );
		var selectedElement = element.select( arguments.tagSelector );

		return ArrayLen( selectedElement );
	}

	private string function _processImages(
		  required string htmlContent
		, required string htmlFileDir
		,          string assetFolder = $getPresideSetting( category="htmlimport", setting="htmlimport_asset_folder", default="importHtmlFiles" )
		,          string pageId      = ""
		,          any    logger
		,          any    progress
	) {
		var hashes = {};
		if ( !$helpers.isEmptyString( pageId ) ) {
			var page = siteTreeService.getPage( pageId );

			if ( !$helpers.isEmptyString( page.main_content ?: "" ) ) {
				hashes = _getHashes( argumentCollection=arguments, htmlContent=page.main_content );
			}
		}

		return dynamicFindAndReplaceService.dynamicFindAndReplace( source=arguments.htmlContent, regexPattern='<img[^>]*src="(.*?)"[^>]*>', recurse=false, processor=function( captureGroups ) {
			var srcPath = arguments.captureGroups[ 2 ] ?: "";

			if ( !$helpers.isEmptyString( srcPath ) ) {
				var fileName = ListLast( srcPath, "/" );
				var filePath = "#htmlFileDir#/#srcPath#";
				var fileHash = Hash( FileReadBinary( filePath ) );

				var assetId = "";
				if ( StructKeyExists( hashes, fileHash ) ) {
					assetId = hashes[ fileHash ];
				} else {
					assetId = assetManagerService.addAsset(
						  folder            = assetFolder
						, ensureUniqueTitle = true
						, fileName          = fileName
						, filePath          = filePath
					);
				}

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
component extends="preside.system.base.AdminHandler" {

	property name="sitetreeService"           inject="SitetreeService";
	property name="htmlImportService"         inject="HTMLImportService";
	property name="htmlImportStorageProvider" inject="HTMLImportStorageProvider";

	public function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );
	}

	public void function index( event, rc, prc, args={} ) {
		setNextEvent( url=event.buildAdminLink( linkTo="HTMLImport.import" ) );
		return;
	}

	public void function import( event, rc, prc, args={} ) {
		var pageId = rc.page ?: "";
		var page   = sitetreeService.getPage( id=pageId, selectFields=[ "id", "page_type", "title" ] );

		var savedData = rc.savedData ?: {
			  page             = page.id        ?: ""
			, child_pages_type = page.page_type ?: ""
			, asset_folder     = getSystemSetting( category="htmlimport", setting="htmlimport_asset_folder", default="importHtmlFiles" )
		};

		args.formName       = "htmlImport.import";
		args.formId         = Replace( args.formName, ".", "-", "all" );
		args.formAction     = event.buildAdminLink( linkTo="htmlImport.importAction" );
		args.formCancelLink = event.buildAdminLink( linkTo="SiteTree.editPage", querystring="id=#pageId#" );
		args.formHtml       = renderForm(
			  formName         = args.formName
			, savedData        = savedData
			, validationResult = rc.validationResult ?: ""
			, context          = "admin"
		);

		prc.pageTitle = translateResource( uri="HTMLImport:title"     );
		prc.pageIcon  = translateResource( uri="HTMLImport:iconClass" );

		var ancestors = sitetreeService.getAncestors( id=pageId, selectFields=[ "id", "title" ] );

		for( var ancestor in ancestors ) {
			event.addAdminBreadCrumb(
				  title = ancestor.title
				, link  = event.buildAdminLink( linkTo="SiteTree.editPage", queryString="id=#ancestor.id#" )
			);
		}

		event.addAdminBreadCrumb(
			  title = page.title ?: ""
			, link  = event.buildAdminLink( linkTo="SiteTree.editPage", queryString="id=#pageId#" )
		);

		event.addAdminBreadCrumb(
			  title = prc.pageTitle
			, link  = ""
		);

		event.include( assetId="/js/admin/specific/htmlImport/" );

		event.setView( view="admin/htmlImport/import", args=args );
	}

	public void function importAction( event, rc, prc, args={} ) {
		var validationResult = validateForms();
		var formData         = event.getCollectionForForm();
		var pageId           = formData.page ?: "";
		var saveAsDraft      = ( rc._saveaction ?: "" ) != "publish";

		if ( !validationResult.validated() ) {
			var persistStruct = event.getCollectionWithoutSystemVars();

			persistStruct.validationResult = validationResult;

			setNextEvent(
				  url           = event.buildAdminLink( linkTo="HTMLImport.import", queryString="page=#pageId#" )
				, persistStruct = persistStruct
			);
		}

		var zipFileName = formData.zip_file.fileName ?: "";
		var zipFilePath = "#CreateUUID()#/#zipFileName#";

		htmlImportStorageProvider.putObject( object=formData.zip_file.binary, path=zipFilePath, private=true );

		StructAppend( formData, { "zip_file"=zipFileName } );

		var taskId = createTask(
			  event      = "admin.HtmlImport.importInBackgroundThread"
			, runNow     = true
			, adminOwner = event.getAdminUserId()
			, title      = "HTMLImport:title"
			, returnUrl  = event.buildAdminLink( linkTo="SiteTree.editPage", queryString="id=#pageId#" )
			, args       = {
				  userId            = event.getAdminUserId()
				, page              = pageId
				, zipFilePath       = zipFilePath
				, pageHeading       = formData.page_heading        ?: ""
				, childPagesHeading = formData.child_pages_heading ?: ""
				, assetFolder       = formData.asset_folder        ?: ""
				, childPagesType    = formData.child_pages_type    ?: ""
				, childPagesEnabled = isTrue( formData.child_pages_enabled ?: "" )
				, isDraft           = saveAsDraft
				, data              = formData
			  }
		);



		event.audit(
			  type     = "htmlImport"
			, action   = "import"
			, recordId = pageId
			, detail   = formData
		);

		setNextEvent( url=event.buildAdminLink(
			  linkTo      = "adhoctaskmanager.progress"
			, queryString = "taskId=" & taskId
		) );
	}

	private boolean function importInBackgroundThread( event, rc, prc, args={}, logger, progress ) {
		htmlImportService.importFromZipFile( argumentCollection=args, logger=arguments.logger, progress=arguments.progress );

		return true;
	}

}
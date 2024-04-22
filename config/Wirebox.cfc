component {

	public void function configure( required any binder ) {
		var settings          = binder.getColdbox().getSettingStructure();
		var s3StorageSettings = settings.s3StorageProvider ?: {};
		var args              = {
			  s3bucket    = s3StorageSettings.bucket    ?: ""
			, s3accessKey = s3StorageSettings.accessKey ?: ""
			, s3secretKey = s3StorageSettings.secretKey ?: ""
			, s3region    = s3StorageSettings.region    ?: "us-east-1"
			, s3subpath   = s3StorageSettings.subpath   ?: ""
		};

		if ( StructKeyExists( s3StorageSettings, "rootUrl" ) ) {
			args.s3RootUrl = s3StorageSettings.rootUrl;
		}

		if ( Len( args.s3accessKey ) && Len( args.s3secretKey ) && Len( args.s3bucket ) ) {
			binder.map( "htmlImportStorageProvider" ).asSingleton().to( "app.extensions.preside-ext-s3-storage-provider.services.S3StorageProvider" ).noAutoWire().initWith(
				  argumentCollection = args
				, s3subPath          = args.s3subPath & "/htmlImportFiles"
			);
		} else {
			binder.map( "htmlImportStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" )
				.initArg( name="rootDirectory"   , value=settings.uploads_directory & "/htmlImportFiles" )
				.initArg( name="privateDirectory", value=settings.uploads_directory & "/htmlImportFiles" )
				.initArg( name="trashDirectory"  , value=settings.uploads_directory & "/.trash" )
				.initArg( name="rootUrl"         , value="" );
		}
	}

}
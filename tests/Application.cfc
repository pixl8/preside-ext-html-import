component {
	this.name = "HTML Import Test Suite";

	this.mappings[ '/tests'   ] = ExpandPath( "/" );
	this.mappings[ '/testbox' ] = ExpandPath( "/testbox" );
	this.mappings[ '/html-import'  ] = ExpandPath( "../" );

	setting requesttimeout=60000;
}

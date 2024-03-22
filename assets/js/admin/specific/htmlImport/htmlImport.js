( function( $ ) {

	var $childPagesEnabled = $( 'input[name="child_pages_enabled"]' )
	  , $childPagesFields  = $( ".html-import-child-pages-field" );

	$childPagesEnabled.on( "change", function() {
		if ( $( this ).is( ":checked" ) ) {
			$childPagesFields.closest( '.form-group' ).show();
		} else {
			$childPagesFields.closest( '.form-group' ).hide();
		}
	} );

	$childPagesEnabled.trigger( "change" );

}) ( presideJQuery );
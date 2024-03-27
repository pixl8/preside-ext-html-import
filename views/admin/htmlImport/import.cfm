<cfscript>
	formId         = args.formId         ?: "";
	formAction     = args.formAction     ?: "";
	formHtml       = args.formHtml       ?: "";
	formCancelLink = args.formCancelLink ?: "";
</cfscript>

<cfoutput>
	<form id="#formId#" action="#formAction#" method="post" enctype="multipart/form-data" class="form form-horizontal">
		#args.formHtml#

		<div class="row form-actions">
			<div class="col-md-offset-2">
				<a href="#formCancelLink#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i> #translateResource( uri="cms:cancel.btn" )#
				</a>

				<button name="_saveaction" value="save" tabindex="#getNextTabIndex()#" class="btn btn-info">
					<i class="fa fa-save bigger-110"></i> #translateResource( uri="HTMLImport:button.save.title" )#
				</button>

				<button name="_saveaction" value="publish" type="submit" tabindex="#getNextTabIndex()#" class="btn btn-warning">
					<i class="fa fa-globe bigger-110"></i> #translateResource( uri="HTMLImport:button.publish.title" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>
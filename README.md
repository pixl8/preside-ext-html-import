# HTML Import

This extension offers a straightforward solution for importing HTML content into your Preside pages.

## Getting started

The zip file must contain at least one *.html file and the folder for images if any.

```
├── index.html
└── images
    ├── hello.jpg
    └── world.png
```

## Allowed page types

To specify the page types that are allowed for importing HTML.

Example: `config/Config.cfc`
```
settings.htmlImport.allowedPageTypes = [ "standard_page" ];
```

## Custom heading

To specify custom page heading with CSS selector instead of standard h1 to h5.

Example: `config/Config.cfc`
```
settings.enum.htmlImportPageHeading = settings.enum.htmlImportPageHeading ?: []
ArrayAppend( settings.enum.htmlImportPageHeading, "p.title>span" );
```

Example: `i18n/enum/htmlImportPageHeading.properties`
```
p.title>span.label=Title (Google Docs)
```

## License

This project is licensed under the GPLv2 License - see the LICENSE.txt file for details.

## Code of conduct

We are a small, friendly and professional community. For the eradication of doubt, we publish a simple code of conduct and expect all contributors, users and passers-by to observe it.

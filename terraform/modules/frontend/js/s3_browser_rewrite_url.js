function handler(event) {
    var request = event.request;
    var uri = request.uri;

    /* Thomas I don't understand what it is used for, it is weird that all the following URLs are lost
    ** Andrew Z originally wrote this code, I updated it to add /data and then removed this cases.
    ** I cannot tell if that makes the behavior better or worse or the same.

    if (uri.startsWith('/data/pds-aria-share-setup-copy-test/')) {
        request.uri = '/';
    }
    else if (uri.startsWith('/data/pds-infrastructure-temp/')) {
        request.uri = '/';
    }
    else if (uri.startsWith('/data/noaa/')) {
        request.uri = '/';
    }
    else if (uri.startsWith('/data/catalina-sky-survey/')) {
        request.uri = '/data/';
    }
    else if (uri.startsWith('/data/aria-share/')) {
        request.uri = '/';
    }
    else if (uri.startsWith('/data/galileo/')) {
        request.uri = '/';
    }
    else if (uri.startsWith('/data/sbn-test/')) {
        request.uri = '/';
    }
    else
    */

    /* the path to data stores is removed because we want to come back to the main page front-end.
       the access to the back-end cloudfront distributon (data store) is handled by the javascript
       code in the user's browser.
    */
    if (uri.startsWith('/data/catalina-sky-survey')) {
        request.uri = '/';
    }
    /* the path to the main page is on the base root of the s3 bucket origin */
    else if (uri.startsWith('/data/')) {
        request.uri = uri.replace('/data', '');
    }



    return request;
}

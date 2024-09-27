function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.includes('.')){
        // for resources like .css, .js, etc...
        // just remove the first /prefix of the URI which is used to redirect
        // from the cloudfront distribution to the origin
        const indexSecondSlash = uri.indexOf("/", 1);
        request.uri = uri.slice(indexSecondSlash);
    }
    else {
        request.uri = '/';
    }

    return request;

}
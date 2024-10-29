function handler(event) {
    var dns = event.context.distributionDomainName;
    var request = event.request;
    var uri = request.uri;

    // find the second slash in URI after the first at character 0
    const indexSecondSlash = uri.indexOf("/", 1);


    if (uri.includes('.')){
        // for resources like .css, .js, etc...
        // just remove the first /prefix of the URI which is used to redirect
        // from the cloudfront distribution to the origin
        request.uri = uri.slice(indexSecondSlash);

    }
    else if (indexSecondSlash == -1) {
        // no second slash found, uri is /prefix or /prefixthing
        // (/prefix* being the configured pattern in the cloudfront behavior)
        // we redirect on the same URL with a trailing / added
        // This is done because the one app applications do not support the missing trailing / on 10/08/2024
        var redirection_url = uri + "/";
        console.log("redirection request to " + redirection_url);
        var response = {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers:
                { "location": { "value":  redirection_url} }
            };
        return response;
    }
    else {
        request.uri = '/';
    }

    console.log("request send to origin is " + request.uri);

    return request;

}
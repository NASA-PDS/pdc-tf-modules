/*
Cloudfront Function which performs URL rewrite to direct requests of the form:
    /api/search/<version>/<request>
to:
    /<request>

The function also removes extra / for example in pds.nasa.gov/api/search/1/products//dfghgh...

*/

var TARGET_URI_PREFIX = "/api/search/1"

// The function is in response to the 'viewer request' event
function handler(event) {
    var request = event.request;
    var incomingUri = request.uri;

    // Strip out any leading multiple slashies - registry-api#208
    incomingUri = incomingUri.replace("//","/");
    request.uri = incomingUri.replace(TARGET_URI_PREFIX, "");
    if (request.uri.length==0){
        // somehow requests with empty uri return 502 bd gateway
        request.uri = "/"
    }
    request.headers["x-forwarded-prefix"] = {"value": TARGET_URI_PREFIX};
    console.log("The request uri to the origin:" + request.uri);
    return request;
}
/*
Cloudfront Function which is used to simplify Nucleus URL from /nucleus/aws_mwaa/aws-console-sso to /nucleus.
*/

function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Rewrite only if the URI is exactly "/nucleus/" or "/nucleus"
    if (uri === "/nucleus" || uri === "/nucleus/") {
        request.uri = "/nucleus/aws_mwaa/aws-console-sso";
    }

    return request;
}

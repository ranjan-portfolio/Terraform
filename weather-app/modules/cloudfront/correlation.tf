resource "aws_cloudfront_function" "inject_trace_header" {
  name    = "inject-trace-header"
  runtime = "cloudfront-js-2.0"
  publish = true

  code = <<-EOF
    async function handler(event) {
      var request = event.request;
      var headers = request.headers;

      var edgeRequestId = headers['x-edge-request-id']
        ? headers['x-edge-request-id'].value
        : 'unknown';

      headers['x-correlation-id'] = { value: edgeRequestId };

      return request;
    }
  EOF
}
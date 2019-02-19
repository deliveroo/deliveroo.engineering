---
layout: post
title:  "Go down the rabbit hole"
authors:
  - "Tim Baker"
excerpt: >
    Debugging a proxy that functions perfectly over the public internet, but fails when inside our Amazon VPC. Or how a friendly man in the middle sent me down a rabbit hole.
---

We have a Go app that acts as the edge service for the tablets Deliveroo partner restaurants use to talk to the rest of the Deliveroo system. Some of the requests are simply proxied to other downstream services. These proxied requests were working over the public internet but POST requests failed when inside our VPC (Virtual Private Cloud). GET requests were still fine.

The change in behaviour was not accompanied by any code changes, just the change in domains we were proxying to.

Our proxy had this code in it:
```go
outgoingRequest, err := http.NewRequest(method, u, incomingRequest.Body)
```

The headers get copied over and after making the `outgoingRequest` the response is returned to the original requester.

Logging in the proxy didn't show anything missing; all body content and headers present on `incomingRequest` were set on `outgoingRequest`, and everything else we could think of to check seemed correct.

Using a downstream rails app that simply dumped everything it received to the logs, we noticed that our POST requests no longer had a body and we had this not particularly helpful Puma error:
`HTTP parse error, malformed request (): #<Puma::HttpParserError: Invalid HTTP format, parsing fails.>`

The logging on the proxy service showed that the body was sent successfully, so we were pretty confused. Some more fumbling around in the dark later this change fixed our problem, all requests were succeeding again:

```go
bodyBytes, _ := ioutil.ReadAll(incomingRequest.Body)

outgoingRequest, err := http.NewRequest(method, u, bytes.NewBuffer(bodyBytes))
```

This is all well and good, but we don't want to read the body, it's a straight pass through proxy, so reading the body is just unnecessary overhead, but now we had something to go on.

Looking more into how NewRequest works, it takes an `io.Reader` as the body. The `io.Reader` interface implements `Read(p []byte) (n int, err error)`. Due to the nature of Go's duck typed interfaces any struct which implements `Read(p []byte) (n int, err error)` can be passed in as the body, effectively it needs some bytes it can read. This is why it compiles and runs: `incomingRequest.Body` is an instance of `ioutil.nopCloser`, a struct respecting the `io.Reader` interface.

However Go's `http.Request` considers some attributes as object/struct level, where out in the world they are conveyed by headers. One of these things is `ContentLength`. This attribute is set by `NewRequest` depending on the type of the `io.Reader` passed in, but there is no implementation for our `ioutil.nopCloser` as it is a stream so does not implement `.Len()`.

So, even though our request came in with a header for content-length, and we copy the request headers over, we don't have a content-length header on our outgoing request. Resulting in our strange puma error from the rails app.

The fix is to manually copy the ContentLength from the incoming request to the outgoing request:

```go
outgoingRequest, err := http.NewRequest(method, u, incomingRequest.Body)

outgoingRequest.ContentLength = incomingRequest.ContentLength
```

Updating this code and looking at the output of our downstream logging app all the proxy service is fully functioning again. We confirmed the fix with our logging:

Without fix:
```
Request to "https://external-domain/log" has content length: 607
Request to "https://internal-domain/log" has content length: 0

...

Request to "https://external-domain/log" has body {"foobar": "baz"}
Request to "https://internal-domain/log" has body
```

With fix:
```
Request to "https://external-domain/log" has content length: 607
Request to "https://internal-domain/log" has content length: 607

...

Request to "https://external-domain/log" has body {"foobar": "baz"}
Request to "https://internal-domain/log" has body {"foobar": "baz"}
```

We had fixed our proxy, but we still didn't know why a request was malformed when sent over our VPC, but arrived correctly when sent over the public internet. We considered a number of differences that could be in play between the public internet and the internal network, a few we considered:

1) Could there be something else about the request having an effect? These were pretty basic HTTP POST requests with small JSON payloads, no chunked transfer encoding, so we ruled this out.

2) The frame size could be different between the public internet and VPC. So in one case the entire request could have been read in one frame, and in the other it could be broken up. For example if the frame size is ~1500 bytes over the public internet but 9k over the VPC could this result in our behaviour? We disregarded this as the private network has a larger frame size, and it is the side that is broken.

3) Something in front of our public domains was 'fixing' the requests before they got to us. This seemed the most likely option so we set about investigating.

We needed to know exactly what was present in our request at each step. So we created a second test app, this time written in Go, with an endpoint that simply returns all headers and body content received, and using [Charles](https://www.charlesproxy.com/) as a local proxy, to show us exactly what we were sending as our request, made requests against it using a simple Go script mimicking the behaviour of our proxy.

The response confirmed the behaviour, requests made within the VPC were arriving without the content-length and requests over the public internet were arriving with the correct content-length header set.

Turning our attention to the outgoing requests we realised that our initial dismissal of chunked encoding had turned out to be a mistake. According to Charles our outgoing request contained a header
"Transfer-Encoding": "chunked", something we were not explicitly adding and was not present on the original `incomingRequest`.

To add to the confusion, this new chunked encoding header was not received by our test app when requests were sent over the public internet, and was replaced by the correct content length. But it was being received when requests were sent inside the VPC.

We have more more questions than answers at this point, so to recap:

It seems our hypothesis is correct, something in front of our services is manipulating our requests. What we have so far:

Outgoing request | Incoming request (within VPC) | Incoming request (over public internet)
--------- | --------- | ---------
Content length header not set | Content length not set | Content length set correctly
Transfer encoding header set to chunked | Transfer encoding header set to chunked | Transfer encoding header not set

Questions:
1. Why do we have a chunked encoding header on our outgoing request if we're not adding it?
2. What is removing this chunked encoding header and replacing it with a correct (previously missing) content length header?

We found the answer to question 1 pretty quickly; as with the content length behaviour implemented in `NewRequest`, the chunked encoding header was being added to our requests due to assumptions made by the Go standard library.

Later on in the proxy process we rely on net/http Client to actually make our request. When the body is processed there is an assumption that if content-length is not present then the request should be sent with a "Transfer-Encoding": "chunked" header. The actual implementation can be found [here](https://github.com/golang/go/blob/2012227b01020eb505cf1dbe719b1fa74ed8c5f4/src/net/http/transfer.go#L107).

The second question had an obvious hypothesis, that our CDN was doing the work to 'correct' the request. So as anyone this far down a rabbit hole would do, we started prodding it to see how far it went.

First we sent a payload of 15kb, well over the standard frame size of the internet, and the behaviour was the same, the chunked header was gone and the correct content length was present.

We kept increasing the payload all the way up to 3MB and the behaviour remained consistent. The CDN must be caching the entire request in order to create the behaviour we were seeing. At this point I got in touch with our platform engineering team to clarify what was happening.

They confirmed that our CDN is working as a man in the middle proxy, and it is expected behaviour for requests to be batched in their entirety before they're passed on to the backend servers and some headers (including Content-Length) are updated to reflect this. This gives some efficiency benefits, and also prevents a type of dos attack where data drip fed in saturates all your workers.

The man in the middle proxy behaviour is similar that found in NGINX buffers:

[NGINX buffers](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/#configuring-buffers)
```
By default NGINX buffers responses from proxied servers. A response is stored in the internal buffers and is not sent to the client until the whole response is received. Buffering helps to optimize performance with slow clients, which can waste proxied server time if the response is passed from NGINX to the client synchronously. However, when buffering is enabled NGINX allows the proxied server to process responses quickly, while NGINX stores the responses for as much time as the clients need to download them.
```

So there we go, the end of our rabbit hole. In summary:

When proxying requests in the way we were you must explicitly copy over content length from the incoming request as the incoming request body does not implement length. If you don't then Go assumes you intend to send a chunked request and adds the required headers.

Our CDN 'fixes' these requests as part of its work as a man in the middle proxy and that's why simply switching from the public internet to the VPC causes our otherwise identical request to fail.

It's a pretty niche problem, but took quite a while to crack.

Some further information about the areas covered:

* golang ioutil [implementation](https://golang.org/src/io/ioutil/ioutil.go)
* golang http.NewRequest [docs](https://golang.org/pkg/net/http/#NewRequest)
* golang http.NewRequest [implementation](https://golang.org/src/net/http/request.go?s=26446:26515#L782)
* golang http.Client [docs](https://golang.org/pkg/net/http/#Client)
* golang http.Client [implementation](https://golang.org/src/net/http/client.go)
* [Charles web debugging proxy](https://www.charlesproxy.com/)
* [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
* [NGINX buffers](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/#configuring-buffers)

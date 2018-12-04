---
layout: post
title:  "How to use Charles Proxy to rewrite HTTPS traffic for web applications"
authors:
  - "Tom Sabin"
excerpt: >
  Charles Proxy is an application that sits between your computer and the Internet to record HTTP(S) traffic. Most importantly for me, it has the ability to also modify a server's HTTP response. I've been using Charles over the past few weeks to rewrite responses from our APIs and I've been slowly learning what Charles is capable of but also what it isn't. Needless to say, there's still a lot to learn, but the defining moment for me was when I was able to recreate a production bug, by replaying the JSON payloads to my local development server causing the same error to be raised.

---

When I first started using Charles Proxy, I was quite overwhelmed by the UI and how everything fitted together. This blog post will help you demystify the application, setup to inspect HTTPS traffic and demonstrate how to use Charles to rewrite requests and responses in three different ways.

For clarity, all examples in this post use Charles Proxy v4.2.7 for macOS Mojave.

## Inspecting HTTPS traffic

If you haven't already, I'd suggest [downloading Charles](https://www.charlesproxy.com/documentation/installation/) and installing the app to follow along.

On the first boot you'll be prompted with a dialog to automatically configure your network settings. You'll need to _Grant Privileges_ for Charles to work correctly.

<figure>
![Grant Privileges to Automatic macOS Proxy Configuration dialog](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/00-grant-priviledges-dialog.png)
</figure>

Once granted, the main interface will open and there will likely be a flurry of activity that shows up in the _Structure_ view. This list will quickly become full of different domains, so you can _Focus_ on specific ones by right clicking to only show focused domains. Alternatively, use the _Filter_ search input found on the bottom left of the window.

Try reloading this page and you'll notice that for HTTPS requests, all resources will show as \<unknown>.

<figure>
![Encrpyted content](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/01-before.png)
</figure>

Fear not, for it is quite simple to install the Charles Root Certificate and configure individual URLs so that you can inspect the page's contents.

<figure>
![Decrypted content](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/02-after.png)
</figure>

To get to this point, you'll need to install the Charles Root Certificate. For macOS find _Install Charles Root Certificate_ from _Help → SSL Proxying_ in the menu bar to add the certificate to Keychain Access.

<figure>
![Add certification from Help item](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/03-install-cert.png)
</figure>

If it doesn't pop up, and only opens Keychain Access it's likely you've installed it in the past - you should be able to find it by searching for Charles (just make sure you've got _All Items_ selected before searching).

Once you've added the certificate, you need to double click to open the certificate window and change the Trust settings to _Always Trust_. Close the window to save.

<figure>
![Trusting certificate from Keychain Access](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/04-trust-certificate.png)
</figure>

The last step is to configure a URL so that you can inspect the domain's traffic. If this isn't configured for the URL then you'll see _SSL Proxying not enabled for this host_ in the _Notes_ row of the _Overview_ panel as shown below.

<figure>
![Notes row suggesting what to do next](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/05-notes.png)
</figure>

As the note suggests, you'll need to find _SSL Proxying Settings_ from _Proxy_ in the menu bar. Add the full domain (e.g. `deliveroo.engineering`) or make use of wildcards. Just avoid making an entry of only `*` (wildcard): that will definitely start breaking all sorts of things unexpectedly.

You should now start to see the HTTPS traffic for that domain, try refreshing the browser page and you'll notice as well that the icon next the domain has changed to a lightning bolt to show that _SSL Proxying enabled for this host_.

## Rewriting traffic with Breakpoints

Now that we can inspect both HTTP and HTTPS traffic, we can start rewriting responses. The quickest way to achieve this is to use a _Breakpoint_. These are set up for specific resources (or _Locations_ as they're called in Charles Proxy) and will pause the response for us to modify before it reaches the client.

You can right click on any level of the resource tree structure to create a breakpoint.

<figure>
![Create breakpoint from right click](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/06-breakpoints.png)
</figure>

Without any dialogs or notification, this creates a _Request & Response_ breakpoint. You can see the entry (and future ones) from _Breakpoint Settings_ found in the _Proxy_ menu bar item. If you don't want to pause for requests (I have never needed this), you can configure the breakpoint to be only for responses - double click on the breakpoint entry and uncheck _Request_.

<figure>
![Edit Breakpoint dialog to uncheck Request option](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/07-edit-breakpoint.png)
</figure>

The next time you make a request that matches the URL, Charles will show a new tab listing the responses and/or requests queued up. This queue can quickly become overwhelming if your matcher is too greedy, shows both requests and responses or that the site is making regular poll requests. The _Status_ row will be helpful in determining what's going.

<figure>
![Breakpoint tab with paused response](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/08-breakpoint-status.png)
</figure>

From within this tab, you can edit everything about the response: headers, cookies, JSON/HTML, etc. using the _Edit Response_ subtab. Try changing the page's response body using the different views available.

After you've edited something, you have a choice of actions to take:

- _Execute_ applies the changes and allow the response to reach its destination,
- _Cancel_ discards your changes but continues to send the response,
- _Abort_ kills the response, simulating a network failure.

<figure>
![Altered HTML in browser](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/09-breakpoints-rewrite.png)
</figure>

## Rewriting traffic with the Rewrite tool

_Breakpoints_ are a quick way to rewrite payloads and modify status codes, but it becomes time consuming for responses you want to modify the same way each time. Thankfully, Charles has other features to make this easier. One of them is called _Rewrite_ and they can be used to modify almost everything about the request and/or response, without interuption and for each time they're made.

We'll use a _Rewrite_ to modify the JSON body from [https://reqres.in/api/users/1](https://reqres.in/api/users/1) (actual response shown below). Remember to setup a _SSL Proxying_ setting for this new host.

```bash
# Use Charles Proxy HTTP Proxy (default port 8888) to pick up the request from cURL
$ curl --proxy localhost:8888 -s https://reqres.in/api/users/1 | jq .
{
  "data": {
    "id": 1,
    "first_name": "George",
    "last_name": "Bluth",
    "avatar": "https://s3.amazonaws.com/uifaces/faces/twitter/calebogden/128.jpg"
  }
}
```

First, copy the full URL of the endpoint and navigate to _Rewrite_ from the _Tools_ menu bar item. _Enable Rewrite_ setting and add a new set. Then add a _Location_ (URL) that defines the set. Paste the URL to the Host field and hit Tab ⇥ to auto deconstruct the URL into the relevant fields.

<figure>
![Create a Rewrite by pasting into the Host field](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/10-rewrite.png)
</figure>

Now we can add a _Rewrite Rule_ to change the JSON response body to `{"foo":"bar"}`.

<figure>
![Rewrite response body with JSON value](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/11-rewrite-json.png)
</figure>

The _Match_ regex used here is optional for this particular example, but you may find it useful in the future to target only JSON-like responses. You may want to use this if you have CORS preflight requests that you don't want to modify. Thanks to [Austin on Stackoverflow](https://stackoverflow.com/a/52438123) for this workaround.

After the _Rewrite Rule_ has been added, be sure to _Apply_ the changes and make the request again. If you've used a browser to make these requests, you may need to force reload or disable cache. For our cURL output, we now have our modified response instead of the original:

```bash
$ curl --proxy localhost:8888 -s https://reqres.in/api/users/1 | jq .
{
  "foo": "bar"
}
```

In the _Overview_ tab you'll see a new row for _Notes_ with `Rewrite Tool: body regex match "\{[\S\s]*\}" replacement "{"foo":"bar"}"` so you'll know when your rewrites are working correctly and or when they might not be correctly configured.

<figure>
![Notes row showing body has been altered](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/12-rewrite-notes.png)
</figure>

## Rewriting traffic with Map Local

Another option you have to rewrite responses (and arguably the easiest one to manage) is _Map Local_. You'll find this in both the _Tools_ menu bar item and also at the bottom of the list when right clicking on a domain in the resource list. Let's use the same example as before ([https://reqres.in/api/users/1](https://reqres.in/api/users/1)) to try it out.

If you're rewriting different paths and resources, the most flexible way of setting up a _Mapping_ is to copy the path structure as folders. For our example above, we'd need a folder for each path segment and a file for the final resource that'll contain our JSON response:

```bash
$ mkdir -p ~/Charles/reqres.in/api/users && cd $_ && echo '{ "baz": "qux" }' > 1
```

Next, when creating the _Mapping_, keep the _Path_ field blank and set the _Local path_ to `~/Charles/reqres.in` to represent the site.

The next time the request is made, it'll match the URL paths to our newly created directory structure and respond with the contents of the file.

Once again, you can verify that this is working if you take a look in the _Overview_ tab and specifically the _Notes_ row: `Mapped to local file: /Users/[username]/Charles/reqres.in/api/users/1`.

<figure>
![Map Local setup with matching directory structure](/images/posts/how-to-use-charles-proxy-to-rewrite-https-traffic-for-web-applications/13-map-local.png)
</figure>

I'd love for us to be using this in our development workflow, but unfortunately the _Mapping_ cannot be filtered by HTTP method, which causes all sorts of troubles for OPTIONS requests (used for CORS preflight requests). The preflight request matches the URL and therefore the response is rewritten and causes a bunch of browser errors, including:

> Access to fetch at '[url]' from origin has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No ‘Access-Control-Allow-Origin' header is present on the requested resource. If an opaque response serves your needs, set the request's mode to ‘no-cors' to fetch the resource with CORS disabled.

We've had to settle with using _Rewrites_ instead, targeting responses that already have a JSON body, so we know Charles is not modifying the CORS response. For now, the [workaround](https://stackoverflow.com/a/52438123) (matching the body to `\{[\S\s]*\}`) is working, but it's definitely not as easy as using _Map Local_.

## Future thoughts

When it comes to local development, Charles has become an invaluable tool to rewrite the API responses without the need to hack around the application code. However, keep in mind that this has been within the context of client side JavaScript making the requests. Some frontend web applications that we work on are backed by a Next.js server that also provides server side rendering. This server will also make requests to the same APIs, which currently show in Charles Proxy still as \<unknown>. It seems that the process that is running the Node server isn't using the web proxy that Charles' automatically set up in my System Preferences from first application load. There's likely a few more hoops that I need to jump through to configure the local server correctly.

I hope that future versions of Charles Proxy will support matching URLs also by HTTP methods not just for _Breakpoints_, as it'll open the doors to using _Map Local_ more often but also to not need workarounds for the _Rewrite_ tool. But for now, those workarounds are working for us.

---
layout: post

title: Shipping services more quickly with design-first OpenAPI contracts
authors:
  - "Jamie Tanna"
excerpt: >
  How using OpenAPI has led to being able to ship a new service more
  effectively, by removing the need to write scaffolding, and instead focus on
  the business logic.
date: 2022-06-27T16:27:23+0100
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

I'm Jamie, and I recently joined the Care Applications team as a Senior Software Engineer. In Care Applications we build and maintain software that connects consumers, riders, restaurants and agents, making sure everyone has a great experience with Deliveroo.

When I joined, we were just starting work on a new service, the Care Request API, which will be used to link together all the possible channels from various first and third parties to our own internal objects.

In the weeks leading up to me joining, the team had worked very hard on preparing important information around the service's key requirements, the data model we'd be working with, and key functionality we'd need to fulfil, which meant I was coming in just as we were ready to sit down and start coding.

When we discussed how we were going to design the API, I brought my previous experience in [the government API programme](https://www.api.gov.uk/) and some of the common practices being used across the global API community, which generally revolve around design-first APIs using OpenAPI. I've used it heavily in the past, and have had some great experiences using it not only for documentation, but to make delivery of APIs much quicker.

# What is OpenAPI?

Now, before we go any further, let's dig into what OpenAPI is.

[OpenAPI](https://openapis.org) is a specification (that had a previous iteration you may have previously heard called Swagger) which is a way to document RESTful APIs in a (fairly) human-readable and machine-readable format.

This specification can be hand-written, or machine-generated from code, into the YAML or JSON formats, and because it's machine-readable, it can be leveraged by tools to make building APIs much easier.

# Why OpenAPI?

OpenAPI is the de facto standard for RESTful API specifications, providing a single view of your API documentation, and because of its widespread support, it [has great tooling support](https://openapi.tools) , The great tooling support gives us the chance to supercharge our development, allowing us to speed up the whole life cycle of service development.

By using OpenAPI, we can reduce a lot of boilerplate and scaffolding that comes with setting up a new endpoint. For instance, instead of needing to  manually create the request/response objects, add a route in your framework for the given path and method, and then check for required/optional parameters, OpenAPI code generators allow us to generate framework-dependent code. This means that instead of focussing engineer time on wiring things in, we can focus on the value-add for the service such as the underlying business logic.

OpenAPI isn't just for generating server-side code. We can also generate API clients, so you don't need to worry about creating a spec-compliant implementation to communicate to another service, and we can generate representative mock servers with dynamically generated data based on the API specification using tools like [Stoplight Prism](https://github.com/stoplightio/prism/).

One concern of working with OpenAPI is that large YAML or JSON documents aren't the most readable. Fortunately, there are tools like [Swagger UI](https://swagger.io/tools/swagger-ui/) or [Stoplight Elements](https://github.com/stoplightio/elements) that provide a better, more human-readable view of the API, with included "try me!" functionality to allow for easier one-off testing, too.

Another common issue with building APIs is the chance that you may break something for a consumer. But if you have an OpenAPI contract, you can perform contract testing to validate that you've not broken what consumers expect, before you push to production. There are various tools for contract testing such as [openapi.tanna.dev/go/validator](https://gitlab.com/jamietanna/httptest-openapi/) (a tool I happened to write) for Go and [Committee](https://github.com/interagent/committee) for Ruby.

Finally, storing your organisation’s API contracts in OpenAPI allows you to understand where inconsistencies between APIs can be improved, and you can start to apply some governance around API design.

# Design-first API development

When developing APIs, there are (generally) two choices to how to develop it - design-first or code-first.

There's still a lot of discussion in the API community ([Stoplight](https://blog.stoplight.io/api-first-api-design-first-or-code-first-which-should-you-choose), [APIs You Won’t Hate](https://apisyouwonthate.com/blog/api-design-first-vs-code-first), [Postman](https://blog.postman.com/many-paths-to-api-first-choose-your-own-adventure/)) around which is "the right way", but my preference for new code is design-first. In design-first, we think about what the endpoint would look like, what would be returned from it, and then write code. This is the opposite to code-first API design, where you would write the code, then write the documentation.

Hand-crafting thousands of lines of OpenAPI's YAML or JSON may not be your favourite thing to do, so there are fortunately tools to make the design-first process easier; or for code-first, you can generate documentation from the written code. Beware though, as generating from existing code can fall down where the tools don't have understanding of your framework or tools.

One of the _huge_ benefits of writing the documentation first is ensuring that a change is explicitly considered, documented, and then implemented, instead of just being a result of what you've done. It allows you to think about whether the change is a good idea first and foremost, instead of just documenting that decision.

I will caveat this with the fact that this is a new service - we're able to start design-first as we are starting from scratch, but it's very infrequent you're working on greenfield projects!

If you've got a service with existing endpoints, documenting the whole thing in one go may be a bit too much work, but you can add it bit-by-bit as you introduce new functionality to endpoints, and absolutely go for design-first for new endpoints.

# Worked example

Now we've talked about the benefits of OpenAPI and design-first API development, let's have a look at what it actually looks like.

We'll use the following OpenAPI specification for this example:

```yaml
openapi: 3.1.0
info:
  title: Care Request API
  version: 0.1.0
paths:
  "/request/{request-id}":
    get:
      summary: Get all requests
      operationId: getRequest
      parameters:
        - $ref: '#/components/parameters/RequestId'
        - $ref: '#/components/parameters/TracingId'
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CareRequest'
        # we'd also add other response options here too
components:
  parameters:
    RequestId:
      name: request-id
      in: path
      required: true
      schema:
        $ref: '#/components/schemas/RequestId'
    TracingId:
      description: A unique tracing ID that can be used for end-to-end tracing
      name: tracing-id
      in: header
      required: false
      schema:
        type: string
        format: uuid
        pattern: "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89abAB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}"
  schemas:
    CareRequest:
      type: object
      properties:
        id:
          $ref: '#/components/schemas/RequestId'
        status:
          $ref: '#/components/schemas/RequestStatus'
    RequestId:
      type: string
      format: uuid
      pattern: "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89abAB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}"
    RequestStatus:
      type: string
      enum:
        - active
        - completed
```

If we run this through the excellent [`oapi-codegen`](https://github.com/deepmap/oapi-codegen), for instance using the [`gorilla/mux`](https://github.com/gorilla/mux) server, this gives us the following high-level interface:

```go
// slightly modified for brevity

type TracingId = uuid.UUID

type GetRequestParams struct {
	// A unique tracing ID that can be used for end-to-end tracing <-- taken from our OpenAPI
	TracingId *TracingId `json:"tracing-id,omitempty"`
}

// ServerInterface represents all server handlers.
type ServerInterface interface {
	// Get all requests <-- taken from our OpenAPI
	// (GET /request/{request-id})
	GetRequest(w http.ResponseWriter, r *http.Request, requestId RequestId, params GetRequestParams)
}
```

The `ServerInterface` is the interface that we need to implement ourselves, and gives us a quite trimmed down set of code to write, focussing on all the endpoint(s) that are required by the service, without a lot of the plumbing to get to that point.

The actual heavy lifting for the endpoint is part of the following generated code:

```go
// slightly modified for brevity

type ServerInterfaceWrapper struct {
	Handler            ServerInterface
	HandlerMiddlewares []MiddlewareFunc
	ErrorHandlerFunc   func(w http.ResponseWriter, r *http.Request, err error)
}

func (siw *ServerInterfaceWrapper) GetRequest(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var err error

	// ------------- Path parameter "request-id" -------------
	var requestId RequestId

	err = runtime.BindStyledParameter("simple", false, "request-id", mux.Vars(r)["request-id"], &requestId)
	if err != nil {
		siw.ErrorHandlerFunc(w, r, &InvalidParamFormatError{ParamName: "request-id", Err: err})
		return
	}

	var handler = func(w http.ResponseWriter, r *http.Request) {
		siw.Handler.GetRequest(w, r, requestId)
	}

	for _, middleware := range siw.HandlerMiddlewares {
		handler = middleware(handler)
	}

	handler(w, r.WithContext(ctx))
}

// ...
func HandlerWithOptions(si ServerInterface, options GorillaServerOptions) http.Handler {
	r := options.BaseRouter

	// ...
	wrapper := ServerInterfaceWrapper{
		Handler:            si,
		HandlerMiddlewares: options.Middlewares,
		ErrorHandlerFunc:   options.ErrorHandlerFunc,
	}

	r.HandleFunc(options.BaseURL+"/request/{request-id}", wrapper.GetRequest).Methods("GET")

	return r
}
```

Notice that the optional `tracing-id` header is added as an optional parameter in a `params` object, and all of the binding for the path variable for the `request-id` and the `tracing-id` is handled in the `ServerInterfaceWrapper`. The `ServerInterfaceWrapper` is used under the hood, and delegates to our implementation.

You may notice that we're not doing _all_ the validation in the `ServerInterfaceWrapper`.

This is because there's a handy middleware we can run which validates incoming requests to make sure that consumers' requests are valid:

```go
r := mux.NewRouter()
// embedded OpenAPI specification that's generated by `oapi-codegen`
spec, err := getSwagger()
// ...

r.Use(middleware.OapiRequestValidator(spec))

api.HandlerFromMux(petStore, r)
```

This means that in our handlers that implement `ServerInterface`, we can assume that a valid request is being passed to us.

Hopefully this gives you a taster of how you are able to reduce the work required by development teams (as a lot of the boilerplate is removed) and instead the focus is on implementing a much more focussed HTTP handler function. This gives us more time to focus on the important work, rather than retrieving request parameters, or routing the request.

This approach also makes it super simple to switch HTTP servers, as we no longer have any implementation details in our HTTP handlers, only a generic interface to the handler.

# Conclusion

The great thing about this workflow is that your API documentation become integral to anything you do.  Since it becomes your source of truth, the motivation exists to ensure that it's kept up to date, which is great for other engineers and consumers.

Being able to utilise the specification to generate a lot of code, performing validation as per our specification, means we spend more time on the value-add work rather than the boilerplate.

All of these lead to a much quicker time-to-delivery, and help us to ship code much faster, and improves the quality and accuracy of our work.

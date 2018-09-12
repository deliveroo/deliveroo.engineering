---
layout: post
title:  "Testing with Third Party Services in Go"
authors:
  - "Tim Baker"
excerpt: >
    Taking advantage of Golang's duck typed interfaces and net/http/httptest to test third party dependencies in web applications.
---

A working application demonstrating the techniques below - and where all code samples are lifted from - can be found [here](https://github.com/timpwbaker/mocking_go)

This post describes an approach to testing the role of a third party dependency throughout a Go application, outlining two different patterns to be used at different stages depending on what it is you're testing at the time.

The first approach takes advantage of Go's interface type to provide a mocked implementation of the dependency to be used in tests. This works well when the third party is peripheral to the code under test. The second approach shows how you can use httptest.NewServer to test the dependency directly by providing a real http server, running locally, to test against.

## If it quacks like an interface, mock it

Imagine you need to audit behaviour in your application. Whenever certain actions are taken, you need to send details as an HTTP post request to the auditor.

The actual implementation looks like this:
```go
func ValidatePost(p *Post, auditorclient auditor.Client) bool {
  auditorclient.Audit("Validate Post", p.ID)

  return validate(p)
}
```

When testing a function that needs auditing the auditor is probably not relevant to your test. What you want to know is that the `ValidatePost` function did what it should. But there's still that bit of your code that audits the request, and that needs to succeed for your test to pass. Here it makes sense to design auditorclient as an instance of Go's native interface type.

Using an interface means that you can provide an implementation of the interface that makes real calls to the outside world in production, but in testing you can use a mocked implementation of the interface, not making any external http calls at all.

Your auditor client needs to have one function: Audit

The first step is to define an interface with that method:
```go
package auditor

...

type Client interface {
  Audit(event string, userID string) error
}
```

As Go's interfaces are duck types, any type that implements all the functions on an interface can be used in place of that interface at any time. So in our case we only need to implement the `Audit` function for any type to be an `auditor.Client`.

Our production implementation is as follows:
```go
package auditor

...

type RealClient struct {
  RequestURL string
}

func (rc *RealClient) Audit(event string, userID string) error {
  payload := buildPayload(event, userID)

  req, err := http.NewRequest("POST", rc.RequestURL, payload)

  client := &http.Client{}
  resp, err := client.Do(req)
  if err != nil {
    panic(err)
  }
  log.Printf("successful request. resp: %v", resp)

  return nil
}
```

Then our mocked implementation, as before only defining the required Audit function:
```go
package auditor


type MockClient struct {
  RequestURL string
}

func (rc *MockClient) Audit(event string, userID string) error {
  log.Printf("Successfully mocked the audit function")
  return nil
}
```

In your tests you can now provide the mocked interface anywhere where you're not interested in the behaviour of the auditor.

You can then put a test together using these parts as follows:

```go
package posts_test

func TestValidatePost(t *testing.T) {
  // First we must resolve our dependecies as the mocked implementations.
  deps := deps.Resolve(deps.Test)

  // The deps require an implementation of the auditorclient.Client interface,
  // in this case our resolver returns the mocked implementation defined above.
  auditorclient := deps.Auditor
  post := posts.Post{ID: "abs7xf", Name: "Testing with third parties in Go"}

  // This code path calls auditorclient.Audit, but the client is the mocked version.
  valid := posts.ValidatePost(&post, auditorclient)

  // Using the mocked version of the auditorclient means we can assert
  // against what we care about - that the post is valid, practically
  // ignoring the auditorclient all together.
  if valid != true {
    t.Error("Should be valid")
  }
}

...

package deps

var Test string = "test"

func Resolve(env string) *Dependencies {
  deps := new(Dependencies)
  if env == Test {
    deps.Auditor = auditor.LoadMock()
  } else {
    requestURL := os.Getenv("AUDITOR_URL")
    deps.Auditor = auditor.LoadClient(requestURL)
  }

  return deps
}
```

This approach prevents your application from ever making any external requests. The `MockClient` implements `Audit`, but it's implementation does nothing.

You could chose to use a mocking library like testify/mock as part of your MockClient. This would allow you to test more behaviour surrounding the mock.

## When a mock just won't do

At some point though you're going to need to test the client itself, and this requires a different approach.

One possible option is to stub the http layer of your application. Those familiar with webmock/rspec in rails will recognise this pattern:

```ruby
stub_request(:post, "http://audit-service.deliveroo.test/audit")
  .to_return(:status => 200, :body => "", :headers => {})
```

But Go's httptest package (net/http/httptest) provides a nice way to take this a step further. `httptest.NewServer` spins up a real web server on your local machine and returns you the url it is running on, something like http://localhost:563242. You can provide the test server with some canned responses and then make real http requests against it.

Below is the test server definition we will use when testing our auditorclient:

```go
// This type allows us to store the json posted to our test local web server
type m map[string]interface{}

var posted m

testServer := httptest.NewServer(

  // NewServer takes a handler.
  http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

    // Inside the handler we define our canned responses,
    // switching on URL and then http method
    switch r.URL.Path {
    case "/reports":
      switch r.Method {
      case "POST":

        // Here we read the body that has been posted to our test server
        // and save it to a variable, we can assert against this variable later.
        body, _ := ioutil.ReadAll(r.Body)
        must(t, json.Unmarshal(body, &posted))
        httputil.SendJSON(w, 200, m{})

        // Finally provide some defaults, I generally just use a 404
      default:
        httputil.SendJSON(w, 404, nil)
      }
    default:
      httputil.SendJSON(w, 404, nil)
    }
  }),
)
defer testServer.Close()
```

The above will create a test server, and store the testServer url in an environment variable for later. We also store whatever is posted to the `/reports` endpoint in the form of a map stored in a variable called posted. This allows you to test the behaviour of the `RealClient.Audit` method in its entirity, right up to the point it makes external requests.

By asserting against the posted variable we can test that our client has hit a particular endpoint of our test server - in this case /reports - with a particular json payload.

If you remember our RealClient struct contains a requestURL attribute, we populate it using the location of the test server as follows:

```go
func LoadClient(requestURL string) *RealClient {
  return &RealClient{
    RequestURL: requestURL,
  }
}
```

You can then test the behaviour of your Audit function where the only difference between your test and production is that you're making requests against a webserver running on your local machine, rather than out there on the Internet. The test could look like this:

```go
func TestAudit(t *testing.T) {

  testServer := httptest.NewServer(
    ... Setup test server here ...
  )

  // Build your auditorclient configured for your test by using the testServer.
  auditorclient := auditor.LoadClient(testServer.URL+"/reports")

  // Call the Audit function on the actual instance of *RealClient
  auditorclient.Audit("Validate Post", "74561")

  // The client will hit our test web server defined above, and save the payload
  // as a map in the variable 'posted'. We can then assert against it.
  if posted["event"] != "Validate Post" {
    t.Error("Posted event should be 'Validate Post'")
  }

  // We know that we've made a real http request, albeit to a test server, and
  // that our auditorclient package is behaving as it is expected to.
  if posted["user_id"] != "74561" {
    t.Error("Posted user_id should be '74561'")
  }
}

```

Now this is obviously moving the stub further down the road, you are still defining what you expect of your third party service and it will need to be kept up to date as that third party could change. But it is very close close to full end to end testing of an application, and is worthy of consideration when deciding how to test the parts of your application related to third parties.

Combining these two patterns is one approach to testing the relationship between your Go web application and third parties. It won't be suitable for everything, but provides a good starting point in most cases.

## Bonus points

You can also augment this approach if your third party requires some kind of authentication. Imagine our auditor requires us to communicate with http_basic auth, you can simply assert that the correct headers are in place inside the test server handler. The entire test might look like this:

```go
func TestAuditAuthenticated(t *testing.T) {
  // Set some environment variables that the client will use to make
  // authenticated requests.
  os.Setenv("AUDITOR_USERNAME", "foobar")
  os.Setenv("AUDITOR_PASSWORD", "baz")

  testServer :=
    httptest.NewServer(
      http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        switch r.URL.Path {
        case "/reports":
          switch r.Method {
          case "POST":

            // Here you can assert that the http basic auth credentials passed
            // in to the test third party service are what you expect them to be,
            // if they're not you can fail the test.
            user, password, ok := r.BasicAuth()
            if ok != true {
              t.Error("Invalid http basic auth credentials")
            }
            if user != "foobar" {
              t.Error("Incorrect http basic username")
            }
            if password != "baz" {
              t.Error("Incorrect http basic password")
            }

            // Beyond this the test is exactly the same as above
            body, _ := ioutil.ReadAll(r.Body)
            must(t, json.Unmarshal(body, &posted))
            httputil.SendJSON(w, 200, m{})
          default:
            httputil.SendJSON(w, 404, nil)
          }
        default:
          httputil.SendJSON(w, 404, nil)
        }
      }),
    )
  defer testServer.Close()

  auditorclient := auditor.LoadClient(testServer.URL + "/reports")
  auditorclient.AuditAuthenticated("Validate Post", "74561")

  if posted["event"] != "Validate Post" {
    t.Error("Posted event should be 'Validate Post'")
  }
  if posted["user_id"] != "74561" {
    t.Error("Posted user_id should be '74561'")
  }
}
```

Some further information about the areas covered:

* The Go standard library [testing package](https://golang.org/pkg/testing/)
* The [httptest package](https://golang.org/pkg/net/http/httptest/)
* [Testify](https://godoc.org/github.com/stretchr/testify), not used here, but a great package for mocking and testing.

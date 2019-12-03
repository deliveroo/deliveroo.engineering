---
layout: post
title:  "Increasing TestFlight Adoption With the App Store Connect API"
authors:
  - "Frédéric Gauchet"
excerpt: >
  How Deliveroo uses the App Store Connect API to check if a new TestFlight build is available and prompt employees to install it.

---

At Deliveroo, we rely on TestFlight to ensure that the app ships to the App Store with as few issues as possible. We don’t have manual testers and since we operate in 13 countries and support a number of country specific features and payment options, it is important to get as many people as possible to install the latest beta to cover most use cases. To do this we prompt employees in app with a modal screen to invite them to install the latest beta.

<figure class="small">
![Deliveroo TestFlight prompt](/images/posts/testflight-app-store-connect-api/testflight-prompt.png)
</figure>

The prompt is shown when the app detects it is out of date by comparing the app version with the latest version available on TestFlight. Until recently configuring the latest TestFlight version required a manual step during the release process. The developer in charge of releasing the app that week needed to update a configuration tool to set the latest available TestFlight version. We’ve now automated that step by using the App Store Connect API.

## Fetching the TestFlight Version From the App Store Connect API

The [App Store Connect API](https://developer.apple.com/app-store-connect/api/) is a REST API that can be used to access various areas of App Store Connect, such as user management, TestFlight, etc. This API is still relatively new: it was announced at WWDC 2018 and released in November 2018.

One use case that was particularly interesting to us was fetching the build number of the latest TestFlight public beta from App Store Connect. We came up with the following query to fetch the info we needed:

```
$ curl -g “https://api.appstoreconnect.apple.com/v1/builds?limit=10&sort=-version&filter[app]=<apple_app_id>&include=buildBetaDetail” --Header “Authorization: Bearer <generated JWT token>”
```

In the query above, replace `<apple_app_id>` with your own app ID.
The JWT token can be generated with the script below, taken from the [WWDC video presentation](https://developer.apple.com/videos/play/wwdc2018-303/?time=2019) about the App Store Connect API.

The curl request above returns some JSON that contains amongst other things, the build number of the latest ten betas. It is then simple enough to look for the highest version number that has the following state: `“externalBuildState”: “IN_BETA_TESTING”`. You’ll have to do a bit of processing: The response contains a “data” object which contains the version number and an “included” object which contains the build state. You can map the version number to a build state by joining on the opaque IDs.

## Authenticating with App Store Connect API

Authentication is done with JSON Web Token which can be created with a private key created on App Store Connect, in the Users and Keys section. The key only needs Developer access, not Admin.

As you must not embed a private key within an app we built a service to query the API. At the last [company hack day](/2019/10/02/where-are-they-now.html) we set out to build an AWS lambda (to avoid adding more code to our monolith backend) to fetch the version information.

The lambda takes around 2 seconds to run, most of this time is spent waiting for a response from the App Store Connect API. This is a long delay and means the configuration endpoint can’t query the lambda directly, even occasionally or it would increase latency for some requests. A simple solution has been to have a background worker query the lambda periodically and cache the result in Redis. Here is an overview of how the final system is set up:

<figure>
![Diagram for App Store Connect APi Usage at Deliveroo](/images/posts/testflight-app-store-connect-api/app-store-connect-lambda.png)
</figure>

## Try It Yourself

1. Go to App Store Connect Users and Access section
2. Create an API key, make a note of the Key ID and issuer ID.
3. Download the key and save it securely, you will not be able to download it again
4. Place the file in a folder
5. Copy the script below in a file named `testflight.rb` for example and place it in the same folder as your private key. Set the values for `ISSUER_ID`, `KEY_ID` and `APP_ID`.
6. Run the script: `$ ruby testflight.rb`. This should print something like `Latest TestFlight beta version: 21566`

```ruby
require 'net/https'
require 'uri'
require 'json'
require 'base64'
require 'jwt'

ISSUER_ID = "<replace-with-issuer-id>"
KEY_ID = "<replace-with-key-id>"
APP_ID = "<replace-with-app-id>"

def generate_token
  private_key = OpenSSL::PKey.read(File.read("AuthKey_#{KEY_ID}.p8"))
  JWT.encode(
   {
    iss: ISSUER_ID,
    exp: Time.now.to_i + 20 * 60,
    aud: "appstoreconnect-v1"
   },
   private_key,
   "ES256",
   header_fields={ kid: KEY_ID }
  )
end

def fetch_latest_version
  uri = URI.parse("https://api.appstoreconnect.apple.com/v1/builds?limit=10&sort=-version&filter[app]=#{APP_ID}&include=buildBetaDetail")
  header = {"Authorization": "Bearer #{generate_token}"}
  response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
    request = Net::HTTP::Get.new(uri.request_uri, header)
    http.request(request)
  end
  parsed = JSON.parse(response.body)

  buildIDMap = parsed["data"].map { |buildInfo|
    [buildInfo["id"], buildInfo["attributes"]["version"]]
  }.to_h

  betaDetailsMap = parsed["included"].map { |betaDetails|
    [betaDetails["id"], betaDetails["attributes"]["externalBuildState"]]
  }.to_h

  versionsInBetaTest = buildIDMap.select { |id|
    betaDetailsMap[id] == "IN_BETA_TESTING" 
  }.map { |id, version|
    version
  }

  versionsInBetaTest.sort.last
end

puts "Latest TestFlight beta version: #{fetch_latest_version}"
```

## Conclusion

With the App Store Connect API we’ve been able to facilitate TestFlight onboarding for all employees. The number of food delivery orders placed from a TestFlight build has more than doubled and our confidence to release a new version has increased.

From my perspective this has been an interesting project which introduced me to AWS lambdas, Golang, and our Ruby on Rails stack. We’re always hiring and if you’re interested in both iOS and backend development, you should consider joining [our team](https://careers.deliveroo.co.uk).

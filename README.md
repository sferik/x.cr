[![tests](https://github.com/sferik/x.cr/actions/workflows/test.yml/badge.svg)](https://github.com/sferik/x.cr/actions/workflows/test.yml)
[![mutation tests](https://github.com/sferik/x.cr/actions/workflows/crytic.yml/badge.svg)](https://github.com/sferik/x.cr/actions/workflows/crytic.yml)
[![linter](https://github.com/sferik/x.cr/actions/workflows/lint.yml/badge.svg)](https://github.com/sferik/x.cr/actions/workflows/lint.yml)
[![maintainability](https://api.codeclimate.com/v1/badges/40bbddf2c9170742ca9e/maintainability)](https://codeclimate.com/github/sferik/x.cr/maintainability)

# A [Crystal](https://crystal-lang.org) interface to the [X API](https://developer.x.com)
This shard is implemented in Crystal.

## Follow

For updates and announcements, follow [this shard](https://x.com/gem) and [its creator](https://x.com/sferik) on X.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  x:
    github: sferik/x.cr
```

Then run `shards install`

## Usage

First, obtain X credentials from <https://developer.x.com>.

```crystal
require "x"

x_credentials = {
  api_key:             "INSERT YOUR X API KEY HERE",
  api_key_secret:      "INSERT YOUR X API KEY SECRET HERE",
  access_token:        "INSERT YOUR X ACCESS TOKEN HERE",
  access_token_secret: "INSERT YOUR X ACCESS TOKEN SECRET HERE",
}

# Initialize an X API client with your OAuth credentials
x_client = X::Client.new(**x_credentials)

# Get data about yourself
x_client.get("users/me")
# => {"data" => {"id" => "7505382", "name" => "Erik Berlin", "username" => "sferik"}}

# Post
post = x_client.post("tweets", "{\"text\":\"Hello, World! (from @shard)\"}")
# => {"data" => {"edit_history_tweet_ids" => ["1234567890123456789"], "id" => "1234567890123456789", "text" => "Hello, World! (from @shard)"}}

# Delete the post
x_client.delete("tweets/#{post["data"]["id"]}")
# => {"data" => {"deleted" => true}}

# Initialize an API v1.1 client
v1_client = X::Client.new(base_url: "https://api.twitter.com/1.1/", **x_credentials)

# Define a custom response object
struct Language
  property code : String
  property name : String
  property local_name : String
  property status : String
  property debug : Bool
end

# Parse a response with custom array and object classes
languages = v1_client.get("help/languages.json", object_class: Language, array_class: Array(Language))

# Access data with dots instead of brackets
languages.first.local_name

# Initialize an Ads API client
ads_client = X::Client.new(base_url: "https://ads-api.twitter.com/12/", **x_credentials)

# Get your ad accounts
ads_client.get("accounts")
```

See other common usage [examples](https://github.com/sferik/x.cr/tree/main/examples).

## History and Philosophy

This library is a rewrite of the [Twitter Ruby library](https://github.com/sferik/twitter). Over 16 years of development, that library ballooned to over 3,000 lines of code (plus 7,500 lines of tests), not counting dependencies. This library is about 500 lines of code (plus 1000 test lines) and has no runtime dependencies. That doesn’t mean new features won’t be added over time, but the benefits of more code must be weighed against the benefits of less:

* Less code is easier to maintain.
* Less code means fewer bugs.
* Less code runs faster.

In the immortal words of [Ezra Zygmuntowicz](https://github.com/ezmobius) and his [Merb](https://github.com/merb) project (may they both rest in peace):

> No code is faster than no code.

The tests for the previous version of this library executed in about 2 seconds. That sounds pretty fast until you see that tests for this library run in one-twentieth of a second. This means you can automatically run the tests any time you write a file and receive immediate feedback. For such of workflows, 2 seconds feels painfully slow.

This code is not littered with comments that are intended to generate documentation. Rather, this code is intended to be simple enough to serve as its own documentation. If you want to understand how something works, don’t read the documentation—it might be wrong—read the code. The code is always right.

## Features

If this entire library is implemented in just 500 lines of code, why should you use it at all vs. writing your own library that suits your needs? If you feel inspired to do that, don’t let me discourage you, but this library has some advanced features that may not be apparent without diving into the code:

* OAuth 1.0 Revision A
* OAuth 2.0 Bearer Token
* Thread safety
* HTTP redirect following
* HTTP proxy support
* HTTP logging
* HTTP timeout configuration
* HTTP error handling
* Rate limit handling
* Parsing JSON into custom response objects (e.g. OpenStruct)
* Configurable base URLs for accessing different APIs/versions
* Parallel uploading of large media files in chunks

## Sponsorship

The X shard is free to use, but with X API pricing tiers, it actually costs money to develop and maintain. By contributing to the project, you help us:

1. Maintain the library: Keeping it up-to-date and secure.
2. Add new features: Enhancements that make your life easier.
3. Provide support: Faster responses to issues and feature requests.

⭐️ Bonus: Sponsors will get priority support and influence over the project roadmap. We will also list your name or your company's logo on our GitHub page.

Building and maintaining an open-source project like this takes a considerable amount of time and effort. Your sponsorship can help sustain this project. Even a small monthly donation makes a huge difference!

[Click here to sponsor this project.](https://github.com/sponsors/sferik)

## Development

1. Clone the repo:

       git clone git@github.com:sferik/x.cr.git

2. Enter the repo’s directory:

       cd x.cr

3. Install dependencies:

       shards install

4. Run the tests:

       crystal spec

5. Create a new branch for your feature or bug fix:

       git checkout -b my-new-branch

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sferik/x.cr.

Pull requests will only be accepted if they meet all the following criteria:

1. Code must be formatted with `crystal tool format`.
2. All specs must pass (`crystal spec`).
3. 100% code coverage.
4. 100% mutation coverage.

## License

The shard is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

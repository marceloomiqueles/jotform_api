jotform-api-ruby
===============
[Jotform API](https://api.jotform.com/docs/) - Ruby Client


### Installation

Install via git clone:

        $ git clone git://github.com/jotform/jotform-api-ruby.git
        $ cd jotform-api-ruby

### Documentation

You can find the docs for the API at [https://api.jotform.com/docs/](https://api.jotform.com/docs/).

### Authentication

JotForm API requires API key for all user related calls. You can create your API Keys at  [API section](http://www.jotform.com/myaccount/api) of My Account page.

### Examples

Print all forms of the user
    
```ruby
#!/usr/bin/env ruby
require_relative 'JotForm'

jotform = JotForm.new("APIKey")
forms = jotform.getForms()

forms.each do |form|
    puts form["title"]
end
```    

Get latest submissions of the user
    
```ruby
#!/usr/bin/env ruby
require_relative 'JotForm'

jotform = JotForm.new("APIKey")
submissions = jotform.getSubmissions()

submissions.each do |submission|
    puts submission["created_at"] + " " 
    submission["answers"].each do | answer|
        puts "\t" + answer.join(" ")
    end
end
```    

    
First the _Jotform_ class is included from _lib/jotform.rb_. This class provides access to Jotform's API. You have to create an API client instance with your API key.
In case of an exception (wrong authentication etc.), you can catch it or let it fail with a fatal error.

### Supported Endpoints

As of **March 8, 2026**, this client is aligned with the public endpoint groups listed in `https://api.jotform.com/docs/`:

- `/user` (including usage, forms, submissions, subusers, folders, reports, settings, settings key, labels, invoices, register, login, logout)
- `/form` (including questions, properties, submissions, files, webhooks, webhooks delete, clone, reports)
- `/submission` (get, edit, delete)
- `/report` (get, delete)
- `/folder` (get, create, update, delete)
- `/label` (get, create, update, delete, resources, add/remove resources)
- `/system` (`/system/plan/{planName}`)

Note: API docs may change over time. When Jotform adds new endpoints, this client may require updates to stay in sync.

### Testing

Run unit tests:

```bash
rake test
```

Run optional integration tests (live API):

```bash
JOTFORM_API_KEY=your_api_key ruby -Ilib:test test/test_jotform_integration.rb
```

`JOTFORM_BASE_URL` can be set for region-specific API hosts. Default is `https://api.jotform.com`.

### License

This project is licensed under the Apache License 2.0. See `LICENSE.txt` for details.

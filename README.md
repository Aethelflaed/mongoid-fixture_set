# mongoid-fixture_set

This projects aims to provide fixtures for Mongoid the same way you have them with ActiveRecord.

I am relying on the source of ActiveRecord and Mongoid to create this gem.

Please report any issue you may find.

If you'd like to contribute, but pull requests are welcome!

## Install

```ruby
gem 'mongoid-fixture_set'
```

## How to use

In your tests, add:

```ruby
class ActiveSupport::TestCase
  include Mongoid::FixtureSet::TestHelper
  self.fixture_path = "#{Rails.root}/test/fixtures"
end
```

This is also done by `ActiveRecord`, but magically in the railties.

Then when you want to access a fixture:

```ruby
class UsersControllerTest < ActionController::TestCase
  setup do
    @resource = users(:geoffroy)
  end
  
  test 'should get show' do
    get :show, id: @resource
    assert_response :success
  end
end
```

## Currently working features

- Creation of a document from an YAML file.
- `belongs_to` relations
- ERB inside YAML files
- YAML DEFAULTS feature
- Polymorphic `belongs_to`
- `has_many` relations
- `has_and_belongs_to_many` relations
- `TestHelper` module to include in your tests

## Notes

Original fixtures from `ActiveRecord` also uses a selection based on `class_names` for which I haven't seen any use case, so I did not port this feature yet.

I did not find how `ActiveRecord::TestFixtures` defines its `fixture_table_names` so I'm simply searching for *all* YAML files under `self.fixture_path`, which is enough for what I want.

Array attributes are receiving a special treatment, i.e. they are joined with new values, not replaced by the new one. This is used for `has_and_belongs_to_many` relations.

## License

This project rocks and uses MIT-LICENSE.

Copyright 2014 Geoffroy Planquart

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

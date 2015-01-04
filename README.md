# mongoid-fixture_set

This projects aims to provide fixtures for Mongoid the same way you have them with ActiveRecord.

I am relying on the source of ActiveRecord and Mongoid to create this gem, which is in an early development and not yet considered stable enough to use it in production.

Please report any issue you may find.

If you'd like to contribute, let me know first, but pull requests are welcome !

## Currently working features

- Creation of a document from an YAML file.
- belongs_to relations
- ERB inside .yml files
- Polymorphic belongs_to
- has_many relations
- has_and_belongs_to_many relations

## Next steps

- Integration in rails


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

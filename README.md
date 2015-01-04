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

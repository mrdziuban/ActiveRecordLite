# ActiveRecord Lite

Lite version of ActiveRecord written to practice metaprogramming.

## Features

* MassObject class to allow for mass assignment of attributes that get sent in as a hash
* SQLObject class to interact with the database, including inserting, updating, and saving records and finding by ID
* Searchable module to mimic ActiveRecord's ::where method
* `belongs_to`, `has_many`, and `has_one_through` associations
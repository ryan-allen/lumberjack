# Lumberjack

Lumberjack is best summed up as a generic DSL for constructing object trees.

It works great for configuration files, for generating a tree of configuration
objects for later reflection or what-not. But in reality you could use it for
whatever you're willing to dream up.

# Installation

```
gem install lumberjack-dsl
```

# Usage

I apologise for the lack of documentation :) Below is a code example to get you
started, any questions, shoot me a message!

Now, that code example:

```ruby
require 'lumberjack'

class Person

  attr_accessor :age, :gripes, :chums

  def initialize(name)
    @name = name
    @gripes = []
    @chums = []
  end
end

class Gripe
  def initialize(desc)
    @desc = desc
  end
end

tree = Lumberjack.construct do

  # we're in list / instanciate object scope

  @john = person 'John (is a doondy head)' do
    # we instanticated an object, so now we're in attr assignment scope
    age 12 # this is equiv to @john.age = 12
    gripes do # open up a colection on john...
      # now we're back in list / instanticate object scope
      gripe 'untested code' # creating a gripe
      gripe 'no beer' # and another
    end # out of gripes, back to john attr assignment
  end # out of john

  # we're back to creating people:

  person 'Ryan' do
    age 25
  end

  person 'Tim' do
    age 'Infinite'
    chums @john # instance vars are shared across Lumberjack.construct
  end
end

puts tree.inspect
```

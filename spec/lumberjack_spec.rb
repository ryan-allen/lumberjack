$: << '.'
require 'lumberjack'
require 'minitest/autorun'

class Family
  attr_accessor :name, :members, :heritage
  def initialize(name = nil, args = {})
    @name = name
    args.each { |k,v| send "#{k}=", v }
  end
end

class Person
  attr_accessor :given_name, :age
  def initialize(name = nil, age = nil)
    @given_name, @age = name, age
  end
end

class Showroom < Array
end

class Vehicle
  class Heavy < Vehicle
    class ReallyHeavy < Heavy
    end
  end
  attr_accessor :name, :wheels, :person
  def initialize(args = {:name => 'A Car, ya mum'})
    @name = args[:name]
    @wheels = SetOfWheels.new
  end
end

class SetOfWheels < Array
end

class Wheel
  attr_accessor :wear
  def initialize(args)
    @wear = args[:wear]
  end
end

describe Lumberjack do

  it 'construct returns an empty list' do
    Lumberjack.construct.must_be_empty
  end

  it 'testcan create a single class' do
    tree = Lumberjack.construct do
      family {} # api change w/ scoping requires a block to be passed, otherwise can't tell if you're
                # trying to resolve a nested scope
    end
    tree.length.must_equal 1
    tree.first.must_be_instance_of Family
  end

  it 'test can create a single class passing in args' do
    tree = Lumberjack.construct do
      family 'Allen', :heritage => :mixed
    end
    tree.length.must_equal 1
    tree.first.must_be_instance_of Family
    tree.first.name.must_equal 'Allen'
    tree.first.heritage.must_equal :mixed
  end

  it 'can create two classes passing in args' do
    tree = Lumberjack.construct do
      family 'Allen', :heritage => [:english, :irish]
      family 'Ta\'eed', :heritage => [:iranian, :english]
    end
    tree.length.must_equal 2
    tree[0].must_be_instance_of Family
    tree[0].name.must_equal 'Allen'
    tree[0].heritage.must_equal [:english, :irish]
    tree[1].must_be_instance_of Family
    tree[1].name.must_equal 'Ta\'eed'
    tree[1].heritage.must_equal [:iranian, :english]
  end

  it 'can set instance members with block' do
    tree = Lumberjack.construct do
      family do
        name 'Allen'
        heritage [:english, :irish]
      end
    end
    tree.length.must_equal 1
    tree[0].must_be_instance_of Family
    tree[0].name.must_equal 'Allen'
    tree[0].heritage.must_equal [:english, :irish]
  end

  it 'can used mixed constructor and instance members in_blocke' do
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage [:english, :irish]
      end
    end
    tree.length.must_equal 1
    tree[0].must_be_instance_of Family
    tree[0].name.must_equal 'Allen'
    tree[0].heritage.must_equal [:english, :irish]
  end

  it 'create list in scoped instance if block with no args' do
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage [:english, :irish]
        members do # working from here
          person 'Tim', 58
          person 'Jan', 54
          person 'Ryan' do
            age 24
          end
        end
      end
    end
    tree.length.must_equal 1
    tree[0].must_be_instance_of Family
    tree[0].name.must_equal 'Allen'
    tree[0].heritage.must_equal [:english, :irish]
    tree[0].members.length.must_equal 3
    tree[0].members[0].given_name.must_equal 'Tim'
    tree[0].members[0].age.must_equal 58
    tree[0].members[1].given_name.must_equal 'Jan'
    tree[0].members[1].age.must_equal 54
    tree[0].members[2].given_name.must_equal 'Ryan'
    tree[0].members[2].age.must_equal 24
  end

  it 'can take generate arrays with comma semantics and tell the difference' do
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage :english, :irish
      end
    end
    tree[0].heritage.must_equal [:english, :irish]
  end

  it 'will_push element onto object if list accessor is already initialized' do
    vehicles = Lumberjack.construct do
      vehicle :name => 'unicycle' do
        wheels do
          wheel :wear => 'bald'
        end
      end
    end
    vehicles[0].wheels.must_be_instance_of SetOfWheels
  end

  it 'can set initial context to something else besdies an array' do
    showroom = Lumberjack.construct Showroom.new do
      vehicle :name => 'a FERRARRI!!!1'
      vehicle :name => 'a MASERATI!!!1'
      vehicle :name => 'a PORCHE OMG!!!'
    end
    showroom.must_be_instance_of Showroom
    showroom.length.must_equal 3
  end

  # biggest hack ever, use a ! to isntanciate a class to an accessor, must be
  # inferable by the accessor name, such a large hack, but we need it for
  # production, and i'm sure other people will need it, so lets leave this
  # gaping flaw of lumberjack for the time being till we can think of something
  # more nice and appropriate :/ :D
  it 'can create instance of class via bang method' do
    cars = Lumberjack.construct do
      vehicle :name => 'Prius (are owned by rich hippies)' do
        person! 'Ryan' do # i so put my foot in here, i'm not a rich hippy!
          age 25
        end
      end
    end
    eval('Vehicle').must_equal Vehicle
    cars[0].class.must_equal Vehicle
    cars[0].name.must_equal 'Prius (are owned by rich hippies)'
    cars[0].person.must_be_instance_of Person
    cars[0].person.age.must_equal 25
    cars[0].person.given_name.must_equal 'Ryan'
  end

  it 'can create list of primitives' do # not sure this is valid useage (of course it is you big dummy ryan from the past!)
    tree = Lumberjack.construct do
      array [:one, :two, :three]
      array [:four, :five, :six]
    end
    tree.must_equal [[:one, :two, :three], [:four, :five, :six]]
  end

  it 'we got backslashes that resolve scope or something' do
    cars = Lumberjack.construct do
      vehicle :name => 'Normal Car'
      # unfortunatley we need to use parantehseshtheses here :(
      vehicle/heavy(:name => 'Heavy Car')
      vehicle/heavy/really_heavy(:name => 'Really Heavy Heavy Car')
    end
    cars[0].must_be_instance_of Vehicle
    cars[1].must_be_instance_of Vehicle::Heavy
    cars[2].must_be_instance_of Vehicle::Heavy::ReallyHeavy
  end

  it 'we can load in other files' do
    family = Lumberjack.construct do
      family 'Barton' do
        heritage [:dutch, :mongrel_aussie]
        members do
          load_tree_file 'examples/people.rb'
        end
      end
    end

    family.length.must_equal 1
    family.first.must_be_instance_of Family
    family.first.name.must_equal 'Barton'
    family.first.heritage.must_equal [:dutch, :mongrel_aussie]

    family.first.members.size.must_equal 5

    family.first.members.first.given_name.must_equal 'John S'
    family.first.members.first.age.must_equal 50

    family.first.members.last.given_name.must_equal 'Ethan'
    family.first.members.last.age.must_equal 10
  end

  it 'we can share branches that are defined' do
    families = Lumberjack.construct do

      shared_branch :kids do
        person 'Jack', 11
        person 'Jill', 10
      end

      family "Dad's new family" do
        members do
          person 'Dad', 45
          graft_branch :kids
        end
      end

      family "Mum's new family" do
        members do
          person 'Mum', 40
          person 'Red-headed step-child', 8
          graft_branch :kids
        end
      end
    end

    families.length.must_equal 2
    families[0].must_be_instance_of Family
    families[1].must_be_instance_of Family

    families[0].members.size.must_equal 3
    families[0].members.any? {|m| m.given_name == 'Jack'}.must_equal true
    families[0].members.any? {|m| m.given_name == 'Jill'}.must_equal true

    families[1].members.size.must_equal 4
    families[1].members.any? {|m| m.given_name == 'Jack'}.must_equal true
    families[1].members.any? {|m| m.given_name == 'Jill'}.must_equal true
  end

  it 'we can remove twigs with prune' do
    families = Lumberjack.construct do

      shared_branch :kids do
        person 'Jack', 12
        person 'Jane', 10
        person 'Bob', 10
      end

      shared_branch :update_kids do
        prune :age, 10
        person 'Will', 11
      end

      family "Dad's family" do
        members do
          person 'Dad', 45
          person 'Mum', 49
          prune :given_name, 'Mum'
          person 'Mum', 26

          graft_branch :kids
          graft_branch :update_kids
        end
      end
    end

    families[0].members.any? {|m| m.given_name == 'Will' && m.age == 11}.must_equal true
    families[0].members.any? {|m| m.given_name == 'Jack' && m.age == 12}.must_equal true
    families[0].members.any? {|m| m.given_name == 'Mum' && m.age == 26}.must_equal true
    families[0].members.any? {|m| m.given_name == 'Dad' && m.age == 45}.must_equal true
  end

  it 'doesnt share branches that are undefined' do
    # TODO: why does this output funny stuff
    lambda {
      Lumberjack.construct do
        family 'wont work' do
          graft_branch :non_existant
        end
      end
    }.must_raise RuntimeError
  end
end

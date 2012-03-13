require 'bundler'
Bundler.require
$: << '.'
require 'lumberjack'

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
    Lumberjack.construct.should be_empty
  end
  
  it 'testcan create a single class' do
    tree = Lumberjack.construct do
      family {} # api change w/ scoping requires a block to be passed, otherwise can't tell if you're
                # trying to resolve a nested scope
    end
    tree.length.should eq 1
    tree.first.should be_instance_of Family
  end
  
  it 'test can create a single class passing in args' do
    tree = Lumberjack.construct do
      family 'Allen', :heritage => :mixed
    end
    tree.length.should eq 1
    tree.first.should be_instance_of Family
    tree.first.name.should eq 'Allen'
    tree.first.heritage.should eq :mixed
  end
  
  it 'can create two classes passing in args' do
    tree = Lumberjack.construct do
      family 'Allen', :heritage => [:english, :irish]
      family 'Ta\'eed', :heritage => [:iranian, :english]
    end
    tree.length.should eq 2
    tree[0].should be_instance_of Family
    tree[0].name.should eq 'Allen'
    tree[0].heritage.should eq [:english, :irish]
    tree[1].should be_instance_of Family
    tree[1].name.should eq 'Ta\'eed'
    tree[1].heritage.should eq [:iranian, :english]
  end
  
  it 'can set instance members with block' do
    tree = Lumberjack.construct do
      family do
        name 'Allen'
        heritage [:english, :irish]
      end
    end
    tree.length.should eq 1
    tree[0].should be_instance_of Family
    tree[0].name.should eq 'Allen'
    tree[0].heritage.should eq [:english, :irish]
  end
  
  it 'can used mixed constructor and instance members in_blocke' do
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage [:english, :irish]
      end
    end
    tree.length.should eq 1
    tree[0].should be_instance_of Family
    tree[0].name.should eq 'Allen'
    tree[0].heritage.should eq [:english, :irish]
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
    tree.length.should eq 1
    tree[0].should be_instance_of Family
    tree[0].name.should eq 'Allen'
    tree[0].heritage.should eq [:english, :irish]
    tree[0].members.length.should eq 3
    tree[0].members[0].given_name.should eq 'Tim'
    tree[0].members[0].age.should eq 58
    tree[0].members[1].given_name.should eq 'Jan'
    tree[0].members[1].age.should eq 54
    tree[0].members[2].given_name.should eq 'Ryan'
    tree[0].members[2].age.should eq 24
  end
  
  it 'can take generate arrays with comma semantics and tell the difference' do
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage :english, :irish
      end
    end
    tree[0].heritage.should eq [:english, :irish]
  end
  
  it 'will_push element onto object if list accessor is already initialized' do
    vehicles = Lumberjack.construct do
      vehicle :name => 'unicycle' do
        wheels do
          wheel :wear => 'bald'
        end
      end
    end
    vehicles[0].wheels.should be_instance_of SetOfWheels
  end
  
  it 'can set initial context to something else besdies an array' do
    showroom = Lumberjack.construct Showroom.new do
      vehicle :name => 'a FERRARRI!!!1'
      vehicle :name => 'a MASERATI!!!1'
      vehicle :name => 'a PORCHE OMG!!!'
    end
    showroom.should be_instance_of Showroom
    showroom.length.should eq 3
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
    eval('Vehicle').should eq Vehicle
    cars[0].class.should eq Vehicle
    cars[0].name.should eq 'Prius (are owned by rich hippies)'
    cars[0].person.should be_instance_of Person
    cars[0].person.age.should eq 25
    cars[0].person.given_name.should eq 'Ryan'
  end
  
  it 'can create list of primitives' do # not sure this is valid useage (of course it is you big dummy ryan from the past!)
    tree = Lumberjack.construct do
      array [:one, :two, :three]
      array [:four, :five, :six]
    end
    tree.should eq [[:one, :two, :three], [:four, :five, :six]]
  end

  it 'we got backslashes that resolve scope or something' do
    cars = Lumberjack.construct do
      vehicle :name => 'Normal Car'
      # unfortunatley we need to use parantehseshtheses here :(
      vehicle/heavy(:name => 'Heavy Car')
      vehicle/heavy/really_heavy(:name => 'Really Heavy Heavy Car')
    end
    cars[0].should be_instance_of Vehicle
    cars[1].should be_instance_of Vehicle::Heavy
    cars[2].should be_instance_of Vehicle::Heavy::ReallyHeavy
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
    
    family.length.should eq 1
    family.first.should be_instance_of Family
    family.first.name.should eq 'Barton'
    family.first.heritage.should eq [:dutch, :mongrel_aussie]

    family.first.members.size.should eq 5

    family.first.members.first.given_name.should eq 'John S'
    family.first.members.first.age.should eq 50

    family.first.members.last.given_name.should eq 'Ethan'
    family.first.members.last.age.should eq 10
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
    
    families.length.should eq 2
    families[0].should be_instance_of Family
    families[1].should be_instance_of Family
    
    families[0].members.size.should eq 3
    families[0].members.any? {|m| m.given_name == 'Jack'}.should be_true
    families[0].members.any? {|m| m.given_name == 'Jill'}.should be_true
    
    families[1].members.size.should eq 4
    families[1].members.any? {|m| m.given_name == 'Jack'}.should be_true
    families[1].members.any? {|m| m.given_name == 'Jill'}.should be_true
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

    families[0].members.any? {|m| m.given_name == 'Will' && m.age == 11}.should be_true
    families[0].members.any? {|m| m.given_name == 'Jack' && m.age == 12}.should be_true
    families[0].members.any? {|m| m.given_name == 'Mum' && m.age == 26}.should be_true
    families[0].members.any? {|m| m.given_name == 'Dad' && m.age == 45}.should be_true
  end
  
  it 'doesnt share branches that are undefined' do
    # TODO: why does this output funny stuff
    expect {
      Lumberjack.construct do
        family 'wont work' do
          graft_branch :non_existant
        end
      end
    }.to raise_error RuntimeError
  end
end

%w(test/unit lumberjack).each { |f| require f }

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

# tree = Lumberjack.construct do # create a list
#   family do # new Family
#     name 'Allen' # name = on instance of Family, scope :instance
#     members do # assign a list to members =, scope :list
#       person 'Tim', 58 # << Person.new('Tim', 58)
#       person 'Jan', 52
#       person 'Ryan', 25
#       person 'Bridget' do
#         age 22
#       end
#       person do
#         name 'Becca'
#         age 20
#       end
#     end
#   end
# end

class LumberjackTest < Test::Unit::TestCase

  def test_construct_returns_an_empty_list
    assert_equal [], Lumberjack.construct
  end
  
  def test_can_create_a_single_class
    tree = Lumberjack.construct do
      family {} # api change w/ scoping requires a block to be passed, otherwise can't tell if you're
                # trying to resolve a nested scope
    end
    assert 1, tree.length
    assert_kind_of Family, tree.first
  end
  
  def test_can_create_a_single_class_passing_in_args
    tree = Lumberjack.construct do
      family 'Allen', :heritage => :mixed
    end
    assert 1, tree.length
    assert_kind_of Family, tree.first
    assert_equal 'Allen', tree.first.name
    assert_equal :mixed, tree.first.heritage
  end
  
  def test_can_create_two_classes_passing_in_args
    tree = Lumberjack.construct do
      family 'Allen', :heritage => [:english, :irish]
      family 'Ta\'eed', :heritage => [:iranian, :english]
    end
    assert 2, tree.length
    assert_kind_of Family, tree[0]
    assert_equal 'Allen', tree[0].name
    assert_equal [:english, :irish], tree[0].heritage
    assert_kind_of Family, tree[1]
    assert_equal 'Ta\'eed', tree[1].name
    assert_equal [:iranian, :english], tree[1].heritage
  end
  
  def test_can_set_instance_members_with_block
    tree = Lumberjack.construct do
      family do
        name 'Allen'
        heritage [:english, :irish]
      end
    end
    assert 1, tree.length
    assert_kind_of Family, tree[0]
    assert_equal 'Allen', tree[0].name
    assert_equal [:english, :irish], tree[0].heritage
  end
  
  def test_can_used_mixed_constructor_and_instance_members_in_blocke
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage [:english, :irish]
      end
    end
    assert 1, tree.length
    assert_kind_of Family, tree[0]
    assert_equal 'Allen', tree[0].name
    assert_equal [:english, :irish], tree[0].heritage
  end
  
  def test_create_list_in_scoped_instance_if_block_with_no_args
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
    assert 1, tree.length
    assert_kind_of Family, tree[0]
    assert_equal 'Allen', tree[0].name
    assert_equal [:english, :irish], tree[0].heritage
    assert_equal 3, tree[0].members.length
    assert_equal 'Tim', tree[0].members[0].given_name
    assert_equal 58, tree[0].members[0].age
    assert_equal 'Jan', tree[0].members[1].given_name
    assert_equal 54, tree[0].members[1].age
    assert_equal 'Ryan', tree[0].members[2].given_name
    assert_equal 24, tree[0].members[2].age
  end
  
  def test_can_take_generate_arrays_with_comma_semantics_and_tell_the_difference
    tree = Lumberjack.construct do
      family 'Allen' do
        heritage :english, :irish
      end
    end
    assert_equal [:english, :irish], tree[0].heritage
  end
  
  def test_will_push_element_onto_object_if_list_accessor_is_already_initialized
    vehicles = Lumberjack.construct do
      vehicle :name => 'unicycle' do
        wheels do
          wheel :wear => 'bald'
        end
      end
    end
    assert_kind_of SetOfWheels, vehicles[0].wheels
  end
  
  def test_can_set_initial_context_to_something_else_besdies_an_array
    showroom = Lumberjack.construct Showroom.new do
      vehicle :name => 'a FERRARRI!!!1'
      vehicle :name => 'a MASERATI!!!1'
      vehicle :name => 'a PORCHE OMG!!!'
    end
    assert_kind_of Showroom, showroom
    assert_equal 3, showroom.length
  end
  
  # biggest hack ever, use a ! to isntanciate a class to an accessor, must be
  # inferable by the accessor name, such a large hack, but we need it for
  # production, and i'm sure other people will need it, so lets leave this 
  # gaping flaw of lumberjack for the time being till we can think of something
  # more nice and appropriate :/ :D
  def test_can_create_instance_of_class_via_bang_method 
    cars = Lumberjack.construct do
      vehicle :name => 'Prius (are owned by rich hippies)' do
        person! 'Ryan' do # i so put my foot in here, i'm not a rich hippy!
          age 25
        end
      end
    end
    assert_kind_of Person, cars[0].person
    assert_equal 'Ryan', cars[0].person.given_name
    assert_equal 25, cars[0].person.age
  end
  
  def test_can_create_list_of_primitives # not sure this is valid useage (of course it is you big dummy ryan from the past!)
    tree = Lumberjack.construct do
      array [:one, :two, :three]
      array [:four, :five, :six]
    end
    assert_equal [[:one, :two, :three], [:four, :five, :six]], tree
  end

  def test_we_got_backslashes_that_resolve_scope_or_something
    cars = Lumberjack.construct do
      vehicle :name => 'Normal Car'
      # unfortunatley we need to use parantehseshtheses here :(
      vehicle/heavy(:name => 'Heavy Car')
      vehicle/heavy/really_heavy(:name => 'Really Heavy Heavy Car')
    end
    assert_kind_of Vehicle, cars[0]
    assert_kind_of Vehicle::Heavy, cars[1]
    assert_kind_of Vehicle::Heavy::ReallyHeavy, cars[2]
  end
  
  def test_we_can_load_in_other_files
    family = Lumberjack.construct do
      family 'Barton' do
        heritage [:dutch, :mongrel_aussie]
        members do
          load_tree_file 'examples/people.rb'
        end
      end
    end
    
    assert 1, family.length
    assert_kind_of Family, family.first
    assert_equal 'Barton', family.first.name
    assert_equal [:dutch, :mongrel_aussie], family.first.heritage

    assert_equal 5, family.first.members.size

    assert_equal 'John S', family.first.members.first.given_name
    assert_equal 50, family.first.members.first.age

    assert_equal 'Ethan', family.first.members.last.given_name
    assert_equal 10, family.first.members.last.age

  end
  
  def test_we_can_share_branches_that_are_defined
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
    
    assert 2, families.length
    assert_kind_of Family, families[0]
    assert_kind_of Family, families[1]
    
    assert 3, families[0].members.size
    assert families[0].members.any? {|m| m.given_name == 'Jack'}
    assert families[0].members.any? {|m| m.given_name == 'Jill'}
    
    assert 4, families[1].members.size
    assert families[1].members.any? {|m| m.given_name == 'Jack'}
    assert families[1].members.any? {|m| m.given_name == 'Jill'}
  end

  def test_we_can_remove_twigs_with_prune
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

    assert families[0].members.any? {|m| m.given_name == 'Will' && m.age == 11}
    assert families[0].members.any? {|m| m.given_name == 'Jack' && m.age == 12}
    assert families[0].members.any? {|m| m.given_name == 'Mum' && m.age == 26}
    assert families[0].members.any? {|m| m.given_name == 'Dad' && m.age == 45}
  end
  
  def test_we_cant_share_branches_that_are_undefined
    # TODO: why does this output funny stuff
    assert_raise RuntimeError do
      Lumberjack.construct do
        family 'wont work' do
            graft_branch :non_existant
        end
      end
    end
  end
end

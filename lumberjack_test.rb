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

# tree = Lumberjack.construct do # create a list
#   family do # new Family
#     name 'Allen' # name = on instance of Family, scope :instance
#     members do # assign a list to members =, scope :list
#       person 'Tim', 58 # << Person.new('Tim', 58)
#       person 'Jan', 54
#       person 'Ryan', 24
#       person 'Bridget' do
#         age 21
#       end
#       person do
#         name 'Becca'
#         age 19
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
      family
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
  
  # def test_can_create_list_of_primitives # not sure this is valid useage
  #   tree = Lumberjack.construct do
  #     array [:one, :two, :three]
  #     array [:four, :five, :six]
  #   end
  #   assert_equal [[:one, :two, :three], [:four, :five, :six]]
  # end
  
  
end
class Lumberjack

  def self.construct(initial_scope = [], &block)
    builder = new(initial_scope)
    builder.__process(block)
  end

  @@methods_to_keep = /^__/, /class/, /instance_eval/, /method_missing/,
    /instance_variable_(g|s)et/

  instance_methods.each do |m|
    undef_method m unless @@methods_to_keep.find { |r| r.match m }
  end

  def initialize(initial_scope)
    @initial_scope = initial_scope
  end

  def __process(block)
    prepare_scope
    instance_eval(&block) if block
    tree
  rescue
    raise $!
  end

  def /(ignore_me) # syntatic sugar for scope resolution
    self
  end

  def load_tree_file(filename)
    File.open filename, 'r' do |f|
      eval f.read, binding, __FILE__, __LINE__
    end
  end

  def shared_branch(branch_name, &block)
    instance_variable_set "@#{branch_name}", lambda(&block)
  end

  def graft_branch(branch_name)
    branch = instance_variable_get("@#{branch_name}")
    raise "Attemption to graft branch #{branch_name} which is undefined" unless branch
    instance_eval(&branch)
  end

  def prune(method, value)
    current_scope.delete_if do |twig|
      twig.respond_to?(method) && twig.send(method) == value
    end
  end

  def method_missing(*args, &block)
    if still_modifying_scope?(args, block)
      push_to_scope_stack_and_return_self(args)
    else
      assign_to_current_scope(*args, &block)
    end
  end

  private

  def assign_to_current_scope(*args, &block)
    case current_scope_type
      when :instance
        assign_to_instance_with(*args, &block)
      when :array
        assign_to_array_with(*args, &block)
    end
  end

  def assign_to_array_with(*args, &block)
    klass = args.shift
    if within_a_scope?
      module_scope = @scope_stack.collect { |bit| classify bit.to_s }.join('::')
      instance     = eval("#{module_scope}::#{classify klass.to_s}").new(*args)
      @scope_stack = nil
    else
      instance = eval(classify(klass.to_s)).new(*args)
    end
    current_scope << instance # add this instance to the scoped Array
    assign_accessors_within_scope(instance, &block) if block
  end

  def assign_accessors_within_scope(instance, &block)
    evaluate_block_within_context(instance, &block)
  end

  def assign_array_of_subvalues_to_accessor(accessor, &block)
    evaluate_block_within_context(current_accessor(accessor), &block)
  end

  def evaluate_block_within_context(accessor, &block)
    append_scope_with accessor
    instance_eval(&block)
    jump_out_of_scope
  end

  def within_a_scope?
    @scope_stack and @scope_stack.any?
  end

  def assign_to_instance_with(*args, &block)
    accessor = args.shift
    case instance_assignment_behaviour_for(accessor, args, block)
      when :assign_subvalues_to_instance
        assign_subvalues_to_instance(accessor, args, &block)
      when :assign_array_of_subvalues_to_accessor
        assign_array_of_subvalues_to_accessor(accessor, &block)
      when :assign_directly_to_accessor
        current_scope.send("#{accessor}=", *args)
      when :assign_array_directly_to_accessor
        current_scope.send("#{accessor}=", args)
      else
        raise "unknown assignment behaviour '#{assignment_behaviour_for(accessor)}' for accessor '#{acccessor}'"
    end
  end

  def current_accessor(accessor)
    if current_accessor_undefined?(accessor)
      set_current_accessor_as_empty_array(accessor)
    end
    current_scope.send("#{accessor}")
  end

  def set_current_accessor_as_empty_array(accessor)
    current_scope.send("#{accessor}=", [])
  end

  def current_accessor_undefined?(accessor)
    current_scope.send("#{accessor}").nil?
  end

  def assign_subvalues_to_instance(accessor, args, &block)
    instance = eval(classify(accessor.to_s[0...-1])).new(args)
    current_scope.send("#{accessor.to_s[0...-1]}=", instance)
    set_accessors_within_scope(instance, &block) if block
  end

  def set_accessors_within_scope(instance, &block)
    append_scope_with instance
    instance_eval(&block)
    jump_out_of_scope
  end

  def instance_assignment_behaviour_for(accessor, args, block)
    if accessor.to_s[-1].chr == '!' #accessor is an actual instance
      :assign_subvalues_to_instance
    elsif block and args.empty? #accessor is to refer to an array
      :assign_array_of_subvalues_to_accessor
    elsif args.length == 1
      :assign_directly_to_accessor
    else
      :assign_array_directly_to_accessor
    end
  end


  def current_scope_type
    # we're assuming any scope that responds to << must be a collection,
    current_scope.respond_to?(:<<) ? :array : :instance
  end

  def push_to_scope_stack_and_return_self(args)
    (@scope_stack ||= []) << args[0]
    self
  end

  def still_modifying_scope?(args, block)
    # if we only have one arg, and no block, then we're trying to build a
    # module scope, i.e. a/b/c/d would resolve to A::B::C::D,
    args.length == 1 and block.nil?
  end

  def prepare_scope
    @scope = [@initial_scope]
  end

  def append_scope_with(new_scope)
    scope.push new_scope
  end

  def jump_out_of_scope
    scope.pop
  end

  def current_scope
    scope.last
  end

  def tree
    scope.first
  end

  def scope
    @scope
  end

  def classify(str)
    camels = str.split('_')
    camels.collect { |c| c.capitalize }.join
  end

end
class Lumberjack

  def self.construct(initial_scope = [], &block)
    builder = new(initial_scope)
    builder.__process(block)
  end

  @@methods_to_keep = /^__/, /class/, /instance_eval/, /method_missing/,
    /instance_variable_(g|s)et/, /instance_variables/, /inspect/, /send/,
    /^object_id/, /^respond_to/

  instance_methods.each do |m|
    undef_method m unless @@methods_to_keep.find { |r| r.match m }
  end

  def initialize(initial_scope)
    @initial_scope = initial_scope
    @scope_stack ||= []
  end

  def __process(block)
    @scope = [@initial_scope]
    instance_eval(&block) if block
    tree
  rescue
    raise $!
  end

  # syntatic sugar for scope resolution
  def /(ignore_me)
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
      @scope_stack << args.first
    else
      assign_to_current_scope(args, block)
    end
    self
  end

  private

  def assign_to_current_scope(args, block)
    if current_scope.respond_to?(:<<)
      assign_to_array_with(args, block)
    else
      assign_to_instance_with(args, block)
    end
  end

  def assign_to_instance_with(args, block)
    accessor = args.shift
    if accessor.to_s[-1].chr == '!'
      # create class based on the accessor name
      assign_subvalues_to_instance(accessor, args, block)
    elsif block and args.empty?
      # accessor is to refer to an array
      current_array_instance = get_accessor_value(accessor)
      evaluate_block_within_context(current_array_instance, block)
    elsif args.length == 1
      # splat to avoid array and directly assign the argument
      current_scope.send("#{accessor}=", *args)
    else
      # assign array
      current_scope.send("#{accessor}=", args)
    end
  end

  def assign_to_array_with(args, block)
    klass = args.shift
    instance = build_class(klass, args)
    current_scope << instance # add this instance to the scoped Array
    evaluate_block_within_context(instance, block) if block
  end

  def assign_subvalues_to_instance(accessor, args, block)
    accessor_class = accessor.to_s[0...-1]
    instance = build_class(accessor_class, args)
    instance.parent = current_scope if instance.respond_to?(:parent=)
    current_scope.send("#{accessor_class}=", instance)
    evaluate_block_within_context(instance, block) if block
  end

  def build_class(klass, args)
    @scope_stack << klass
    scoped_class = @scope_stack.join('/')
    @scope_stack = []
    classify(scoped_class).new(*args)
  end

  def evaluate_block_within_context(accessor, block)
    @scope.push accessor
    instance_eval(&block)
    @scope.pop
  end

  def get_accessor_value(accessor)
    if current_scope.send("#{accessor}").nil?
      current_scope.send("#{accessor}=", [])
    end
    current_scope.send("#{accessor}")
  end

  def still_modifying_scope?(args, block)
    # if we only have one arg, and no block, then we're trying to build a
    # module scope, i.e. a/b/c/d would resolve to A::B::C::D,
    args.length == 1 && block.nil?
  end

  def current_scope
    @scope.last
  end

  def tree
    @scope.first
  end

  # Turns an underscored path into the class it represents
  #
  # Usage: classify("some/cool_klass") => Some::CoolKlass
  def classify(class_name)
    klass = class_name.split('/').collect do |component|
      camels = component.split('_')
      camels.collect { |c| c.capitalize }.join
    end.join('::')
    eval("::#{klass}")
  end

end

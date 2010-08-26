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
    puts @scope.inspect
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
    # if we only have one arg, and no block, then we're trying to build a
    # module scope, i.e. a/b/c/d would resolve to A::B::C::D, so let's start
    # recording the bits...
    if args.length == 1 and block.nil?
      (@bits ||= []) << args[0]
      self # return us coz we respond to / which does nothing but look good!
    else
      #
      # now we've changed this here, we're assuming any scope that responds
      # to << must be a collection, so we treat it as such - i can't think
      # of any scenarios where this may bunk up, but best to remind myself
      # for later just in case...
      #
      if !current_scope.respond_to?(:<<) # we're working inside an Instance
        accessor = args.shift # grab the accessor name
        if accessor.to_s[-1].chr == '!' # hacky hack instance something
          instance = eval(classify(accessor.to_s[0...-1])).new(*args)
          current_scope.send("#{accessor.to_s[0...-1]}=", instance)
          if block # we got a block, change scope to set accessors
            append_scope_with instance
            instance_eval(&block)
            jump_out_of_scope
          end
        elsif block and args.empty? # we're making an accessor into an array of Instances
          if current_scope.send("#{accessor}").nil?
            current_scope.send("#{accessor}=", [])
          end
          collection = current_scope.send("#{accessor}")
          append_scope_with collection
          instance_eval(&block)
          jump_out_of_scope
        else # it's just a plain old assignment to the accessor
          if args.length == 1
            current_scope.send("#{accessor}=", *args)
          else # it looks like someone is trying to pass an array... so
            #
            # THIS BIT IS FUCKED, take this crap out, it makes the API
            # way too confusing and inconsistent
            #
            current_scope.send("#{accessor}=", args)
          end
        end
      else # scope is an Array, so create an Instance
        klass = args.shift
        # :w

        if @bits and @bits.any?
          module_scope = @bits.collect { |bit| classify bit.to_s }.join('::')
          instance = eval("#{module_scope}::#{classify klass.to_s}").new(*args)
          @bits = nil
        else
          instance = eval(classify(klass.to_s)).new(*args)
        end
        current_scope << instance # add this instance to the scoped Array
        if block # we got a block, change scope to set accessors
          append_scope_with instance
          instance_eval(&block)
          jump_out_of_scope
        end
      end
    end
  end
  
private

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

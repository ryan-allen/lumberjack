%w(rubygems active_support).each { |d| require d }

class Lumberjack
  
  def self.construct(&block)
    builder = new
    builder.__process(block)    
  end
  
  @@methods_to_keep = /^__/, /class/, /instance_eval/, /method_missing/
  
  instance_methods.each do |m|
    undef_method m unless @@methods_to_keep.find { |r| r.match m }
  end
  
  def __process(block)
    prepare_tree
    instance_eval(&block) if block
    tree.first
  rescue
    puts tree.inspect
    raise $!
  end
  
  def method_missing(*args, &block)
    if !current_scope.is_a?(Array)
      attr = args.shift
      current_scope.send("#{attr}=", *args)
    else # scope is an Array, so create an Instance
      klass = args.shift
      instance = eval(klass.to_s.classify).new(*args)
      current_scope << instance
      if block
        append_scope_with instance
        instance_eval(&block)
        jump_out_of_scope
      end
    end
  end
  
private

  def prepare_tree
    @tree = [[]]
  end
  
  def append_scope_with(new_scope)
    tree.push new_scope
  end
  
  def jump_out_of_scope
    tree.pop
  end
  
  def current_scope
    tree.last
  end
  
  def tree
    @tree
  end
  
end
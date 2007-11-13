%w(rubygems active_support).each { |d| require d }

class Lumberjack
  
  def self.construct(&b)
    builder = new
    builder.__process(b)
  end
  
  @@methods_to_keep = /^__/, /class/, /instance_eval/, /method_missing/
  
  instance_methods.each do |m|
    undef_method m unless @@methods_to_keep.find { |r| r.match m }
  end
  
  def __process(b)
    @out = []
    instance_eval(&b) if b
    @out
  end
  
  def method_missing(*args, &c)
    if @scoped_instance
      attr = args.shift
      @scoped_instance.send("#{attr}=", *args)
    else
      klass = args.shift
      @out << eval(klass.to_s.classify).new(*args)
      if c
        @scoped_instance = @out.last
        instance_eval(&c)
        @scoped_instance = nil
      end
    end
  end
  
end
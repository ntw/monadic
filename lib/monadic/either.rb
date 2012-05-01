# Chain various method calls 
module Either
  class NoEitherError < StandardError; end

  def self.chain(initial=nil, &block)
    Either::Chain.new(&block).call(initial)
  end

  def success?
    is_a? Success
  end

  def failure?
    is_a? Failure
  end

  def fetch(default=@value)
    return default if failure?
    return @value
  end
  alias :_     :fetch

  def bind(proc=nil, &block)
    return self if failure?

    begin
      result = if proc && proc.arity == 0 
                 then proc.call
                 else (proc || block).call(@value) 
               end
      result ||= Failure(nil)
      fail_unless_either(result)
      result    
    rescue Exception => ex
      Failure(ex)      
    end
  end
  alias :>=     :bind
  alias :+      :bind
  alias :chain  :bind

  def to_s
    "#{self.class.name}(#{@value.nil? ? 'nil' : @value.to_s})"
  end

  def ==(other)
    return false unless self.class === other
    return other.fetch == @value
  end

  private
  def fail_unless_either(result)
    raise NoEitherError, "Result must return Success or Failure, got #{result.inspect}" unless result.is_a? Either
  end
end

class Either::Chain
  def initialize(&block)
    @chain = []
    instance_eval(&block)
  end

  def call(initial)
    @chain.inject(Success(initial)) do |result, current|
      result.bind(current)
    end
  end

  def bind(proc)
    @chain << proc
  end
  alias :chain :bind

end

class Success 
  include Either
  def initialize(value)
    @value = value
  end
end

class Failure 
  include Either
  def initialize(value)
    @value = value
  end
end

def Success(value)
  Success.new(value)
end

def Failure(value)
  Failure.new(value)
end

def Either(value)
  return Failure(value) if value.nil? || (value.respond_to?(:empty?) && value.empty?) || !value
  return Success(value)
end
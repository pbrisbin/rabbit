class ThreadManager
  def execute_with &block
    @block = block
  end

  def execute_on *args
    @args = args
  end

  def execute!
    results  = []
    eval_str = ''

    @args.each do |arg|
      if arg.class == Symbol
        eval_str << %{
          th_#{arg} = Thread.new do
            results << @block.call(:#{arg})
          end

        }
      else
        eval_str << %{
          th_#{arg} = Thread.new do
            results << @block.call(#{arg})
          end

        }
      end
    end

    @args.each do |arg|
      eval_str << %{
        th_#{arg}.join
      }
    end

    #puts eval_str
    instance_eval eval_str
    return results
  end
end

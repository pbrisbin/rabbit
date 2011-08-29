class ThreadManager
  def execute_with &block
    @block = block
  end

  def execute_on *args
    @args = args
  end

  def execute!
    results = []
    spawned = []

    @args.each do |arg|
      th = Thread.new do
        results << @block.call(arg)
      end

      spawned << th
    end

    spawned.each do |th|
      th.join
    end

    results
  end
end

module ThreadedEach
  # yields to block for each item in a separate thread, waits for all
  # threads to end and returns an array of results. order is
  # non-deterministic by nature.
  def threaded_each(&block)
    results = []
    spawned = []

    self.each do |x|
      th = Thread.new do
        results << block.call(x)
      end

      spawned << th
    end

    spawned.each(&:join)

    results
  end
end

class Enumerator # :nodoc:
  include ThreadedEach
end

class Array # :nodoc:
  include ThreadedEach
end

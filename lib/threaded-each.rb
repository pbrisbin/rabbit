module ThreadedEach
  def threaded_each &block
    results = []
    spawned = []

    self.each do |x|
      th = Thread.new do
        results << block.call(x)
      end

      spawned << th
    end

    spawned.each do |th|
      th.join
    end

    results
  end
end

class Enumerator; include ThreadedEach end
class Array;      include ThreadedEach end

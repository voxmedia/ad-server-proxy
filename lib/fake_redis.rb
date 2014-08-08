# Quick class to emulate redis when running in test mode
# Or if running without redis... horrible and inefficient
class FakeRedis

  TTL = 5 #minutes;

  def initialize
    @store = {}
    # emulate ttl
    @last_deleted = Time.now
  end

  def exists(key)
    response = @store.key? key
    delete_if_ttl_expired
    response
  end

  def setex(key,ttl,value,*args);
    @store.store(key,value)
  end

  def get(key);
    value = @store.fetch(key)
    delete_if_ttl_expired
    value
  end

  private

  def delete_if_ttl_expired
    if (Time.now - @last_deleted) > (TTL * 60)
      @store = {}
      @last_deleted = Time.now
    end
  end
end
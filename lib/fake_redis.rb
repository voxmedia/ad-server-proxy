# Quick class to emulate redis when running in test mode
# Or if running without redis
class FakeRedis

  TTL = 5 #minutes;

  def initialize
    @store = {}
    # emulate a 5 minute ttl
    @last_deleted = Time.now
  end

  def exists(key)
    delete_if_ttl_expired
    @store.key? key
  end

  def setex(key,value,*args);
    delete_if_ttl_expired
    @store.store(key,value)
  end

  def get(key);
    delete_if_ttl_expired
    @store.fetch(key)
  end

  private

  def delete_if_ttl_expired
    if (Time.now - @last_deleted) > TTL * 60
      @store = {}
      @last_deleted = @Time.now
    end
  end
end
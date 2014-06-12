require 'set'

class QuickBooksSync::Conflict
  attr_reader :remote, :local
  def initialize(remote, local)
    @remote, @local = remote, local
  end

  delegate :type, :id, :unique_id, :to => :local

  def differences
    all_attribute_keys.map do |key|
      [key, [remote[key], local[key]]]
    end.select do |key, (r, l)|
      r != l
    end
  end

  private

  def all_attribute_keys
    Set.new(remote.attributes.keys) | Set.new(local.attributes.keys)
  end
end
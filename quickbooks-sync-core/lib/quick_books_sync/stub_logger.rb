module QuickBooksSync
  class StubLogger

    delegate :update, :to => :"self.class"

    def self.update(status)
      puts status
    end
  end

end
module QuickBooksSync::PennyConverter
  extend self

  def to_pennies(amount)
    dollars, cents = amount.to_s.split(".")
    cents =  if cents
      if cents.length == 1
        cents + "0"
      else
        cents
      end
    else
      0
    end

    dollars, cents = [dollars, cents].map(&:to_i)
    (dollars * 100) + cents
  end

  def from_pennies(amount)
    amount.to_s.rjust(3, "0").gsub(/(\d*)(\d\d)/, '\1.\2')
  end

end
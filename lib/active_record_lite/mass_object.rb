class MassObject
  def self.set_attrs(*attrs)
    @attributes = []
    attrs.each do |attribute|
      # Self refers to class itself because class method
      self.send("attr_accessor", attribute)
      @attributes << attribute
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
  end

  def initialize(params = {})
    params.each do |attr_name, attr_value|
      # Self refers to instance of class because of instance method
      if self.class.attributes.include?(attr_name.to_sym)
        send("#{attr_name}=", attr_value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end

# TEST CODE
# class MyMassObject < MassObject
#   set_attrs(:x, :y)
# end

# obj = MyMassObject.new(:x => :x_val, :y => :y_val)
# p obj

module FastExcel
  module AttributeHelper
    def set(values)
      values.each do |key, value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
        elsif respond_to?("set_#{key}=")
          send("set_#{key}=", value)
        else
          self[key] = value
        end
      end

      self
    end

    def fields_hash
      res = {}
      members.each do |key|
        #p [key, self[key]]
        res[key] = respond_to?(key) ? send(key) : self[key]
      end
      res
    end

    def pretty_print(pp)
      pp fields_hash
    end
  end
end

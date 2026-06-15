module FastExcel
  module FormatOptionHelper
    def set(values)
      values.each do |key, value|
        writer = "#{key}="

        raise ArgumentError, "Unknown format option #{key.inspect}" unless respond_to?(writer)

        send(writer, value)
      end

      self
    end
  end
end

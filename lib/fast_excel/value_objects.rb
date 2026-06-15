module FastExcel
  class Formula
    attr_accessor :fml

    def initialize(fml)
      @fml = fml
    end
  end

  class URL
    attr_accessor :url

    def initialize(url)
      @url = url
    end
  end

  class RichString
    attr_reader :fragments

    def initialize(fragments)
      @fragments = fragments.map do |fragment|
        {
          text: fragment.fetch(:text).to_s,
          format: fragment[:format]
        }
      end
    end
  end
end

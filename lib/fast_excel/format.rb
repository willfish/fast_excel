module FastExcel
  module FormatExt
    include AttributeHelper
    include FormatOptionHelper

    [:font_size, :underline, :font_script, :rotation, :indent, :pattern, :border].each do |prop|
      define_method(prop) do
        self[prop]
      end
      define_method("#{prop}=") do |value|
        send("set_#{prop}", value)
      end
    end

    [:bold, :italic, :font_outline, :font_shadow, :hidden, :text_wrap, :font_strikeout, :shrink, :text_justlast].each do |prop|
      define_method(prop) do
        self[prop]
      end
      define_method("#{prop}=") do |value|
        value ? send("set_#{prop}") : self[prop] = false
      end
    end

    [:num_format, :font_name].each do |prop|
      define_method(prop) do
        self[prop].to_ptr.read_string
      end

      define_method("#{prop}=") do |value|
        send("set_#{prop}", value)
      end
    end

    ALIGN_ENUM = Libxlsxwriter.enum_type(:format_alignments)

    # Can be called as:
    #
    #  format.align = :align_center
    #  format.align = "align_center"
    #  format.align = :center
    #  format.align = :align_center
    #  format.align = {v: "center", h: "center"}
    #
    # Possible values:
    #
    #   :align_none, :align_left, :align_center, :align_right, :align_fill, :align_justify,
    #   :align_center_across, :align_distributed, :align_vertical_top, :align_vertical_bottom,
    #   :align_vertical_center, :align_vertical_justify, :align_vertical_distributed
    #
    def align=(value)
      value = value.to_sym if value.is_a?(String)

      if value.is_a?(Symbol)
        if ALIGN_ENUM.find(value)
          set_align(value)
        elsif ALIGN_ENUM.find(prefixed = "align_#{value}".to_sym)
          set_align(prefixed)
        else
          raise ArgumentError, "Can not set align = #{value.inspect}, possible values are: #{ALIGN_ENUM.symbols}"
        end
      elsif value.is_a?(Hash)
        if value[:horizontal]
          self.align = "align_#{value[:horizontal].to_s.sub(/^align_/, '')}".to_sym
        end
        if value[:h]
          self.align = "align_#{value[:h].to_s.sub(/^align_/, '')}".to_sym
        end
        if value[:vertical]
          self.align = "align_vertical_#{value[:vertical].to_s.sub(/^align_vertical_/, '')}".to_sym
        end
        if value[:v]
          self.align = "align_vertical_#{value[:v].to_s.sub(/^align_vertical_/, '')}".to_sym
        end
        possible = [:horizontal, :h, :vertical, :v]
        extras = value.keys - possible
        if extras.size > 0
          raise ArgumentError, "Not allowed keys for align: #{extras.inspect}, possible keys: #{possible.inspect}"
        end
      else
        raise ArgumentError, "value must be a symbol or a hash"
      end
    end

    def align
      {
        horizontal: ALIGN_ENUM.find(self[:text_h_align]),
        vertical:   ALIGN_ENUM.find(self[:text_v_align])
      }
    end

    [:font_color, :bg_color, :fg_color, :bottom_color, :diag_color, :left_color, :right_color, :top_color].each do |prop|
      define_method("#{prop}=") do |value|
        send("set_#{prop}", FastExcel.color_to_hex(value))
      end
      define_method(prop) do
        self[prop]
      end
    end

    [:bottom_color, :left_color, :right_color, :top_color].each do |prop|
      alias_method :"border_#{prop}=", :"#{prop}="
      alias_method :"border_#{prop}", :"#{prop}"
    end

    BORDER_ENUM = Libxlsxwriter.enum_type(:format_borders)

    [:bottom, :diag_border, :left, :right, :top].each do |prop|
      define_method("#{prop}=") do |value|

        send("set_#{prop}", border_value(value))
      end
      define_method(prop) do
        BORDER_ENUM.find(self[prop])
      end

      unless prop == :diag_border
        alias_method :"border_#{prop}=", :"#{prop}="
        alias_method :"border_#{prop}", :"#{prop}"
      end
    end

    def border_value(value)
      # if a number
      return value if value.is_a?(Numeric) && BORDER_ENUM.find(value)

      orig_value = value
      value = value.to_sym if value.is_a?(String)

      return BORDER_ENUM.find(value) if BORDER_ENUM.find(value)
      return BORDER_ENUM.find(:"border_#{value}") if BORDER_ENUM.find(:"border_#{value}")

      short_symbols = BORDER_ENUM.symbols.map {|s| s.to_s.sub(/^border_/, '').to_sym }
      raise ArgumentError, "Unknown value #{orig_value.inspect} for border. Possible values: #{short_symbols}"
    end

    def set_font_size(value)
      if value < 0
        raise ArgumentError, "font size should be >= 0 (use 0 for user default font size)"
      end
      super(value)
    end

    def font_family
      font_name
    end

    def font_family=(value)
      self.font_name = value
    end
  end
end

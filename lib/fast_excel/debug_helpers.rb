module FastExcel
  def self.print_ffi_obj(value, do_print: true, offset: "", deep: false)
    result = "#{value.class}"

    value.members.each do |key|
      fval = value[key]
      field_val = if fval.is_a?(FFI::Pointer) && fval.null? || fval.nil?
        "nil"
      elsif fval.is_a?(FFI::StructLayout::CharArray)
        fval.to_str.inspect
      elsif fval.is_a?(String)
        fval.inspect
      elsif fval.is_a?(Symbol)
        fval.inspect
      elsif fval.is_a?(FFI::Struct) && deep
        print_ffi_obj(fval, do_print: false, offset: offset + "    ", deep: deep)
      else
        fval
      end

      result += "\n#{offset}* #{key}: #{field_val}"
    end

    if do_print
      puts result
    else
      return result
    end
  end
end

module Ethereum
  class Decoder

    def decode(type, value, start = 0)
      value = value.gsub(/^0x/,'')
      core, subtype = Abi::parse_type(type)
      method_name = "decode_#{core}".to_sym
      if core == "string" or core == "bytes"
        self.send(method_name, value, start)
      else
        self.send(method_name, value[start..start+63])
      end
    end

    def decode_uint(value)
      value.hex
    end

    def decode_int(value)
      raise ArgumentError if value.nil?
      (value[0..1] == "ff") ? (value.hex - (2 ** 256)) : value.hex
    end

    def decode_bool(value)
      return true if value == "0000000000000000000000000000000000000000000000000000000000000001"
      return false if value == "0000000000000000000000000000000000000000000000000000000000000000"
      raise ArgumentError
    end

    def decode_address(value)
      raise ArgumentError if value.size != 40
      value
    end

    def decode_bytes(value, start = 0)
      location = decode_uint(value[start..(start+63)]) * 2
      size = decode_uint(value[location..location+63]) * 2
      value[location+64..location+63+size].scan(/.{2}/).collect {|x| x.hex}.pack('C*')
    end

    def decode_string(value, start = 0)
      decode_bytes(value, start).force_encoding('utf-8')
    end

    def decode_arguments(arguments, data)
      data = data.gsub(/^0x/,'')
      types = arguments.map { |o| o.type }
      types.each.with_index.map { |t , i| decode(t, data, i*64) }
    end

  end
end

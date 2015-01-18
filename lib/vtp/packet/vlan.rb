class VTP
  class Packet
    class VLAN
      attr_reader :length, :status, :type, :name_length, :id, :mtu, :index, :name
      def initialize pkt
        parse pkt
      end

      private

      def parse pkt
        @length      = pkt.read(1).ord
        @status      = pkt.read(1).ord
        @type        = pkt.read(1).ord
        if @type < 3
           parse_type pkt
        else  # unupported type
          _padding = pkt.read @length-3
        end
      end

      def parse_type pkt
        @name_length = pkt.read(1).ord
        @id          = pkt.read(2).unpack("n").first
        @mtu         = pkt.read(2).unpack("n").first
        @index       = pkt.read(4).unpack("N").first
        @name        = pkt.read @name_length
        _padding     = pkt.read @length-(@name_length+12)
      end
    end
  end
end

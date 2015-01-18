require 'stringio'
require_relative 'packet/vlan'

class VTP
  class Packet
    attr_reader :version, :code, :sequence, :domain_length, :domain, :revision, :vlan
    def initialize pkt
      @vlan = []
      parse StringIO.new pkt
    end

    private

    def parse pkt
      @version        = pkt.read(1).ord
      @code           = pkt.read(1).ord
      @sequence       = pkt.read(1).ord
      @domain_length  = pkt.read(1).ord
      @domain         = pkt.read @domain_length
      _padding        = pkt.read 32-@domain_length
      @revision       = pkt.read(4).unpack("N").first
      while not pkt.eof?
        vlan = VLAN.new(pkt)
        @vlan << vlan if vlan.type < 3
      end
    end
  end
end

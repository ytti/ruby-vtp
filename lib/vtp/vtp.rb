#!/usr/bin/env ruby

require 'ffi/pcap'
require 'stringio'

class VTP
  INTERFACE = 'eth0'
  FILTER    = 'ether dst host 01:00:0c:cc:cc:cc'
  OFFSET    = 0x16

  def self.capture interface=INTERFACE, filter=FILTER
    new(interface, filter).capture { |pkt| yield pkt }
  end

  def initialize interface, filter
    @cap = FFI::PCap::Live.new dev: interface, timeout: 1, promisc: true, handler: FFI::PCap::Handler
    @cap.setfilter filter
  end

  def capture
    s = OFFSET
    @cap.loop() do |this, pkt|
      ethertype = pkt.body[12..13].unpack("n").first
      s = OFFSET+4 if ethertype == 0x8100 # native vlan tagged
      next unless pkt.body[s..s+1].unpack('s').first == 0x0202 # version 2, code 2
      yield Packet.new pkt.body[s..-1]
    end
  end

  private

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

if $0 == __FILE__
  VTP.capture do |pkt|
    pkt.vlan.each do |vlan|
      puts "%4s => %s" % [vlan.id, vlan.name]
    end
  end
end
# 

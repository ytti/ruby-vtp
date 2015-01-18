require 'ffi/pcap'
require_relative 'packet'

class VTP
  INTERFACE = 'eth0'
  FILTER    = 'ether dst host 01:00:0c:cc:cc:cc'
  OFFSET    = 0x16

  class Error < StandardError; end
  class UnknownOption < Error; end

  def self.capture interface=INTERFACE, filter=FILTER
    new(interface: interface, filter: filter).capture { |pkt| yield pkt }
  end

  def initialize opts
    interface = opts.delete :interface
    filter    = opts.delete :filter
    @debug    = opts.delete :debug
    interface ||= INTERFACE
    filter    ||= FILTER
    @cap = FFI::PCap::Live.new dev: interface, timeout: 1, promisc: false, handler: FFI::PCap::Handler
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
end

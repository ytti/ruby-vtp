class VTP
  class Query
    DMAC = [0x01, 0x00, 0x0c, 0xcc, 0xcc, 0xcc].pack('C*')
    SMAC = ([0x22]*6).pack('C*')
    TYPE = [0x00, 0x00].pack('C*')  # len==0, turns out, csco does not care, same with VLAN
    LLC  = [0xaa, 0xaa, 0x03, 0x00, 0x00, 0x0c, 0x20, 0x03].pack('C*') # snap, snap, 03, cisco, vtp
    VTP  = [0x02, 0x03, 0x00] # we need domain length here + padding
    START   = [0].pack('N')

    def self.inject domain='default', interface=INTERFACE
      new(domain, interface).inject
    end

    def initialize domain, interface
      @net    = FFI::PCap::Live.new device: 'eth0', promisc: false
      vtp     = (VTP + [domain.size]).pack('C*')
      padding = ([0]*(32-domain.size)).pack('C*')
      data    = DMAC + SMAC + TYPE + LLC + vtp + domain + padding + START
      @packet = FFI::PCap::Packet.new nil, data
    end

    def inject
      @net.inject @packet
    end
  end
end

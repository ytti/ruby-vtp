# Ruby VTP Listener

Idea is that I could have lab switch where all my edge lab devices connect 2-3
times, as simulated edge custsomers. This switch would have one VLAN per port,
and then trunk port to linux server. 

When ever new edge lab device is connected to switch and access VLAN created,
linux would automatically create VLAN and network namespace for the VLAN name,
and of course remove when VLAN is removed

Then you could do something like this

    alias vrf="ip netns exec"
    vrf vlan_name1 /bin/zsh
    ip addr add 10.10.1.2/24 dev eth0
    ip route add default via 10.10.1.1
    exit
    vrf vlan_name2 /bin/zsh
    ip addr add 10.10.2.2/24 dev eth0
    ip route add default via 10.10.2.1
    ping 10.10.1.2

And you're pinging through what ever lab topology is in your lab core connecting those two vlans.

# Library use
    require 'vtp'
    require 'open3'
    class NSPOC
      def initialize
        @ns = {}
        run
      end

      def run
         VTP.capture do |pkt|
           new = {}
           pkt.vlan.each do |vlan|
             next unless vlan.type == 1
             new[vlan.name] = vlan.id
           end
           compare new
        end
      end

      def compare new
        old_ns  = @ns.keys
        new_ns  = new.keys
        (old_ns-new_ns).each { |ns| remove ns, @ns[ns] }
        (new_ns-old_ns).each { |ns| add ns, new[ns] }
        @ns = new.dup
      end

      def add name, vlan
        ip 'netns', 'add', name
        ip 'link', 'add', 'link', 'eth0', 'netns', name, 'name', 'eth1', 'type', 'vlan', 'id', vlan.to_s
      end

      def remove name, vlan
        ip 'netns', 'delete', name
      end

      def ip *args
        Open3.popen3('ip', *args) do |stdin, stdout, stderr, wait_thr|
          wait_thr.join
        end
      end
    end
    NSPOC.new

# CLI use
    root@kone:~/foo# vtpd --help
    Usage: vtpd [options]
        -d, --debug          turn on debugging
        -f, --file           store to file
        -i, --interface      specify interface to listen, instead of eth0
        -n, --domain         if set, injects advertisement request on start
        -h, --help           Display this help message.

    # vtpd -f /etc/vtp.json     # would run in background and store vtp information in file
    # vtpd -d                   # would run in foreground and print vtp infromation
    # vtpd -d --domain 'sux'    # requets VTP database immediately on start from domain 'sux'

# JSON format
    root@kone:~/foo/ruby-vtp# cat /tmp/vtp.json
    {
      "domain": "triotto",
      "revision": 96,
      "vlan": [
        {
          "id": 1,
          "name": "default"
        },
        {
          "id": 9,
          "name": "vrrp"
        },
      # rest of the vlans
    }

# TODO
  1. support vtp1 or vtp3? (vtp1 at least will work by just removing the version check)

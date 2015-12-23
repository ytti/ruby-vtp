# Ruby VTP Listener

Idea is that I could have lab switch where all my edge lab devices connect 2-3
times, as simulated edge custsomers. This switch would have one VLAN per port,
and then trunk port to linux server.

When ever new edge lab device is connected to switch and access VLAN created,
linux would automatically create VLAN and network namespace for the VLAN name,
and of course remove when VLAN is removed

The moment VLAN is created, the 'virtual host' is created, IP address assigned,
default GW set. So you can immediately start to ping against the 'client' PC.

You could, of course, also run software at the 'client' PC:

    alias vrf="ip netns exec"
    vrf vlan_name1 /bin/zsh
    telnet server 25
    exit
    vrf vlan_name2 /bin/zsh
    iperf -s -u

And you're pinging through what ever lab topology is in your lab core connecting those two vlans.

# Library use
    require 'vtp'
    require 'open3'
    class NSPOC
      VLAN_TRUNK = "eth1"
      MY_IP = "10"
      GW_IP = "1"
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
        ip 'link', 'add', 'link', 'eth0', 'netns', name, 'name', VLAN_TRUNK, 'type', 'vlan', 'id', vlan.to_s
        net = %w(10) + (%w(0) + vlan.to_s.scan(/.{1,2}/))[-2..-1]
        ip = (net + [MY_IP]).join('.') + '/24'
        gw = (net + [GW_IP]).join('.')
        ip 'netns', 'exec', name, 'ip', 'addr',  'add', ip, 'dev', 'eth0'
        ip 'netns', 'exec', name, 'ip', 'route', 'add', 'default', 'via', gw
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

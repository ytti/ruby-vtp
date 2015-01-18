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
    exit
    vrf vlan_name2 /bin/zsh
    ip addr add 10.10.2.2/24 dev eth0
    ping 10.10.1.2

And you're pinging through what ever lab topology is in your lab core connecting those two vlans.

# Example
    require 'vtp'
    VTP.capture do |pkt|
      pkt.vlan.each do |vlan|
         provision_vlan vlan.id
         provision_namespace vlan.id, vlan.name
      end
    end

# TODO

  1. gemify
  2. support vtp1 or vtp3? (vtp1 at least will work by just removing the version check)
  3. poll for latest vlan database, not sure how to do this, right now, on
     initial start, you won't know the VLANs, the database is only sent on
     changes

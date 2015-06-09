# = Fusor Network
#
# Configures networking according to values gathered by wizard, it does following actions
#   * configures gateway
#   * configures interface's IP address, netmask and DNS servers
#   * adds hosts record if missing
#   * configures firewall in a non-destructive way (leaves all existing rules untouched)
#
# === Parameters:
#
# $interface::            Which interface should this class configure
#
# $ip::                   What IP address should be set
#
# $netmask::              What netmask should be set
#
# $gateway::              What is the gateway for this machine
#
# $dns::                  DNS forwarder to use as secondary nameserver
#
# $configure_networking:: Should we modify networking?
#                         type:boolean
#
# $configure_firewall::   Should we modify firewall?
#                         type:boolean
#
class foreman::plugin::fusor_network(
    $interface,
    $ip,
    $netmask,
    $gateway,
    $dns,
    $configure_networking,
    $configure_firewall,
) {

  if ($configure_networking) {
    class { 'network::global':
      gateway => $gateway,
    }

    network::if::static { $interface:
      ensure    => 'up',
      ipaddress => $ip,
      netmask   => $netmask,
      dns1      => $ip,
      dns2      => $dns,
      peerdns   => true,
    }

    host { $fqdn:
      comment      => 'created by puppet class foreman::plugin::fusor_network',
      ip           => $ip,
      host_aliases => $hostname
    }
  }

  if ($configure_firewall) {
    resources { "firewall":
      purge => true,
      require => Package['iptables-services'],
    } ->
    resources { 'firewallchain':
      purge => true,
      require => Package['iptables-services'],
    }

    Firewall {
      before  => Class['foreman::plugin::fusor_fw_post'],
      require => Class['foreman::plugin::fusor_fw_pre'],
    }

    class { ['foreman::plugin::fusor_fw_post', 'foreman::plugin::fusor_fw_pre', 'firewall']: }

    # The Foreman server should accept ssh connections for management.
    firewall { '22 accept - ssh':
      port   => '22',
      proto  => 'tcp',
      action => 'accept',
    } ->
    # The Foreman server needs to accept DNS requests on this port for tcp and udp when provisioning systems.
    firewall { '53 accept - dns tcp':
      port   => '53',
      proto  => 'tcp',
      action => 'accept',
    } ->
    firewall { '53 accept - dns udp':
      port   => '53',
      proto  => 'udp',
      action => 'accept',
    } ->
    # The Foreman server needs to accept DHCP requests on this port when provisioning systems.
    firewall { '67 accept - dhcp':
      port   => '67',
      proto  => 'udp',
      action => 'accept',
    } ->
    # The Foreman server needs to accept BOOTP requests on this port when provisioning systems.
    firewall { '68 accept - bootp':
      port   => '68',
      proto  => 'udp',
      action => 'accept',
    } ->
    # The Foreman server needs to accept TFTP requests on this port when provisioning systems.
    firewall { '69 accept - tftp':
      port   => '69',
      proto  => 'udp',
      action => 'accept',
    } ->
    # The Foreman web user interface accepts connections on these ports.
    firewall { '80 accept - apache':
      port   => '80',
      proto  => 'tcp',
      action => 'accept',
    } ->
    firewall { '443 accept - apache':
      port   => '443',
      proto  => 'tcp',
      action => 'accept',
    } ->
    # The Foreman server accepts connections to Puppet on this port.
    firewall { '8140 accept - puppetmaster':
      port   => '8140',
      proto  => 'tcp',
      action => 'accept',
    }
    # The Foreman server accepts connections with managed systems on this port.
    firewall { '5671 accept - managed systems':
      port   => '5671',
      proto  => 'tcp',
      action => 'accept',
    }
    # The Foreman server accepts connections to Tomcat on this port.
    firewall { '8080 accept - tomcat6':
      port   => '8080',
      proto  => 'tcp',
      action => 'accept',
    }
    # The Foreman server accepts connections to Smart Proxy on this port.
    firewall { '9090 accept - smart proxy':
      port   => '9090',
      proto  => 'tcp',
      action => 'accept',
    }
  }
}

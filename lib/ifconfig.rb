require 'open3'
require 'json'
require 'pathname'
require 'net/ssh'

def sudo_exec(cmd, *args)
  # Work around nimbus bug where we can't become root.
  Net::SSH.start('127.0.0.1', 'worker',
      password:  'ca$hc0w',
      user_known_hosts_file: '/dev/null',
      paranoid: false) do |ssh|
    # Nimbus has ancient net::ssh v4, which doesn't accept an varargs here, so
    # we have to format an insecure shell command.
    cmdline = ['sudo', '-n', cmd].push(*args)
    ssh.exec!(cmdline.join(" "))
  end
end

# Install Linux network configuration tools. Assumes CentOS >= 8.
def if_install_tools()
  # Work around Nimbus bug https://bugzilla.eng.vmware.com/show_bug.cgi?id=2698984
  File.write("/tmp/99-gateway.conf", "net.ipv4.ip_forward = 1\n")
  sudo_exec('cp', '/tmp/99-gateway.conf', '/etc/sysctl.d')

  # 'kernel-modules-extra' is for the netem module (see https://bugzilla.redhat.com/show_bug.cgi?id=1776748).
  sudo_exec('dnf', 'install', '-y', 'iproute', 'iproute-tc', 'kernel-modules-extra')

  # XXX(jpeach) need to reboot, since the modules package we just installed
  # won't necessarily match the running kernel.
end

def if_install_traffic_shaping(delay, throughput)
  here = File.dirname(File.realpath(__FILE__))

  # Write temp config as current user so we can install it as root.
  File.write("/tmp/traffic-shaping-setup", "DELAY=#{delay}\nTHROUGHPUT=#{throughput}\n")

  # Install traffic script and config.
  sudo_exec('cp', '/tmp/traffic-shaping-setup', '/etc/sysconfig')
  sudo_exec('cp', Pathname.new(here).join('traffic-shaping-setup.sh'), '/usr/local/bin')

  # Install systemd service to start the script on boot.
  sudo_exec('cp', Pathname.new(here).join('traffic-shaping-setup.service'), '/etc/systemd/system')
  sudo_exec('cp', Pathname.new(here).join('traffic-shaping-setup.timer'), '/etc/systemd/system')
  sudo_exec('systemctl', 'daemon-reload')
  sudo_exec('systemctl', 'enable', 'traffic-shaping-setup.timer')
  sudo_exec('systemctl', 'start', 'traffic-shaping-setup.timer')
end

# Parse and return the JSON output of `ip addr show`.
def if_parse_addresses()
  output, status = Open3.capture2('ip', '-j', 'addr', 'show')
  raise "failed to exec 'ip addr show'" unless status.success?

  ifaddrs = Hash.new()

  # At this point, we have an array of interface entries.
  # Turn the array into a map indexed by the interface name.
  for i in JSON.parse(output) do
    ifname = i["ifname"]
    ifaddrs[ifname] = i
  end

  return ifaddrs
end

# Given an interface address entry (from `ip addr show`), return the IPv4
# addresses. We don't bother with IPv4 because who knows whether nimbus
# supports that.
def if_get_addresses(ifaddr)
  addrs = []

  for a in ifaddr["addr_info"] do
    next if a["family"] != "inet"
    addrs << a["local"]
  end

  return addrs
end

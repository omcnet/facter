# Fact: selinux
#
# Purpose:
#
# Resolution:
#
# Caveats:
#

# Fact for SElinux
# Written by immerda admin team (admin(at)immerda.ch)

sestatus_cmd = '/usr/sbin/sestatus'

# This supports the fact that the selinux mount point is not always in the
# same location -- the selinux mount point is operating system specific.
def selinux_mount_point
  path = "/selinux"
  if FileTest.exists?('/proc/self/mounts')
    File.open('/proc/self/mounts') do |f|
      f.grep(/selinuxfs/) do |line|
        path = line.split[1]
        break
      end
    end
  end
  path
end

Facter.add("selinux") do
  confine :kernel => :linux
  setcode do
    result = "false"
    if FileTest.exists?("#{selinux_mount_point}/enforce")
      if FileTest.exists?("/proc/self/attr/current")
        if (File.read("/proc/self/attr/current") != "kernel\0")
          result = "true"
        end
      end
    end
    result
  end
end

Facter.add("selinux_enforced") do
  confine :selinux => :true
  setcode do
    result = "false"
    if FileTest.exists?("#{selinux_mount_point}/enforce") and
       File.read("#{selinux_mount_point}/enforce") =~ /1/i
      result = "true"
    end
    result
  end
end

Facter.add("selinux_policyversion") do
  confine :selinux => :true
  setcode do
    result = 'unknown'
    if FileTest.exists?("#{selinux_mount_point}/policyvers")
      result = File.read("#{selinux_mount_point}/policyvers").chomp
    end
    result
  end
end

Facter.add("selinux_current_mode") do
  confine :selinux => :true
  setcode do
    result = 'unknown'
    mode = Facter::Util::Resolution.exec(sestatus_cmd)
    mode.each_line { |l| result = $1 if l =~ /^Current mode\:\s+(\w+)$/i }
    result.chomp
  end
end

Facter.add("selinux_config_mode") do
  confine :selinux => :true
  setcode do
    result = 'unknown'
    mode = Facter::Util::Resolution.exec(sestatus_cmd)
    mode.each_line { |l| result = $1 if l =~ /^Mode from config file\:\s+(\w+)$/i }
    result.chomp
  end
end

Facter.add("selinux_config_policy") do
  confine :selinux => :true
  setcode do
    result = 'unknown'
    mode = Facter::Util::Resolution.exec(sestatus_cmd)
    mode.each_line { |l| result = $1 if l =~ /^Policy from config file\:\s+(\w+)$/i }
    result.chomp
  end
end

# This is a legacy fact which returns the old selinux_mode fact value to prevent
# breakages of existing manifests. It should be removed at the next major release.
# See ticket #6677.

Facter.add("selinux_mode") do
  confine :selinux => :true
  setcode do
    Facter.value(:selinux_config_policy)
  end
end

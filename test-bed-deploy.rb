oneGB = 1 * 1000 * 1000 # in KB
 
$testbed = Proc.new do
  {
    "name" => "testbed-test",
    "version" => 3,
    "esx" => (0..0).map do | idx |
      {
        "name" => "esx.#{idx}",
        "vc" => "vc.0",
        "customBuild" => "ob-17168206",
        "dc" => "vcqaDC",
        "clusterName" => "cluster0",
        "style" => "fullInstall",
        "cpus" => 8, # 32 vCPUs
        "memory" => 24000, # 98000 98GB memory
        "fullClone" => true,
        "desiredPassword" => "ca$hc0w",
        "disks" => [ 50 * oneGB, 50 * oneGB, 600 * oneGB ], # [ 2 * 1000 * oneGB ] -->  2 TB Disk
        "guestOSlist" => [         
          {
            "vmName" => "centos-vm.#{idx}",
            "ovfuri" => NimbusUtils.get_absolute_ovf("CentOS-7-64-VMTools/CentOS-7-x64.ovf")
          }
        ]
      }
    end,
 
    "vcs" => [
      {
        "name" => "vc.0",
        "type" => "vcva",
        "customBuild" => "ob-17004997",
        "dcName" => ["vcqaDC"],
        "enableDrs" => true,
        "clusters" => [
          {
            "name" => "cluster0",
            "dc" => "vcqaDC"
          }
        ],
        "disks" => [ 600 * oneGB ]
      }
    ],
 
    "beforePostBoot" => Proc.new do |runId, testbedSpec, vmList, catApi, logDir|
    end,
    "postBoot" => Proc.new do |runId, testbedSpec, vmList, catApi, logDir|
    end
  }
end
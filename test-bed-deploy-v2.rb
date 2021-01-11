oneGB = 1 * 1000 * 1000 # in KB
 
$testbed = Proc.new do
  {
    "name" => "testbed-test",
    "version" => 3,

    'worker' => [
        {
            'name' => "worker.0",
            'enableStaticIpService' => true, # turn on static ip server
        },
    ],


    'network' => [
            { 'name' => 'datacenter.0', 'routable' => true },
            # { 'name' => 'remote.1', 'routable' => true },
        ],

    "esx" => (0..2).map do | idx |
      {
        "name" => "esx.#{idx}",
        "vc" => "vc.0",
        "customBuild" => "ob-17168206",
        "dc" => "dc-apj",
        "clusterName" => "cluster-k8s",
        "style" => "fullInstall",
        "cpus" => 16, # 32 vCPUs
        "memory" => 32000, # 98000 98GB memory
        "fullClone" => true,
        "nics" => 3,
        "networks" => ["public" , "nsx::datacenter.0"]
        "desiredPassword" => "ca$hc0w",
        # "disk" => [ 200 * oneGB ], # [ 2 * 1000 * oneGB ] -->  2 TB Disk
        # "ssd" => [ 50 * oneGB, 600 * oneGB ] # [ 2 * 1000 * oneGB ] -->  2 TB Disk

        "disk" => [ 50 * oneGB, 50 * oneGB, 600 * oneGB ], # [ 2 * 1000 * oneGB ] -->  2 TB Disk
        "ssd" => [  50 * oneGB ], # [ 2 * 1000 * oneGB ] -->  2 TB Disk
        "freeLocalLuns" => 2


      }
    end,
 
    "vcs" => [
      {
        "name" => "vc.0",
        "type" => "vcva",
        "customBuild" => "ob-17004997",
        "dcName" => ["dc-apj"],
        "nics" => 2
        "networks" => ["public" , "nsx::datacenter.0"]
        "enableDrs" => true,
        "clusters" => [
          {
            "name" => "cluster-k8s",
            "dc" => "dc-apj"
            "vsan" => true, 
            "enableDrs" => true,
            "enableHA" => true 
          }
        ],
        "disks" => [ 600 * oneGB ]
      }
    ],
 
    "beforePostBoot" => Proc.new do |runId, testbedSpec, vmList, catApi, logDir|
    end,
    "postBoot" => Proc.new do |runId, testbedSpec, vmList, catApi, logDir|
      workerVM = vmList['worker'][0]
      Log.info "static ip service endpoint is #{workerVM.info['nsips']}"
    end
  }
end
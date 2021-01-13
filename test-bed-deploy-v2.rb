## Run  
# nimbus-testbeddeploy  \
# --noStatsDump \
# --customizeWorker "template=worker-centos8" enableStaticIpService \
# --testbedSpecRubyFile "/mts/home5/rfoe/scripts/test-bed-deploy-v2.rb" \
# --resultsDir "/mts/home5/rfoe/tmp" \
# --runName "rfoe-test" \
#  --isolated-testbed

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



    # force_public -> bind to nimbus public network
    # public -> bind to isolated_network vxlan  192.168.111.0/24 GW 192.168.111.1 DNS 192.168.111.1
    # net.0 -> bind to isolated_network vxlan  192.168.112.0/24 GW 192.168.112.1 DNS 192.168.112.1
    # net.1 -> bind to isolated_network vxlan  192.168.113.0/24 GW 192.168.113.1 DNS 192.168.113.1
    
    'network' => [
            
            { 'name' => 'net.0', 'routable' => true },
            { 'name' => 'net.1', 'routable' => true },
        ],

    "esx" => (0..2).map do | idx |
      {
        "name" => "esx.#{idx}",
        "vc" => "vc.0",
        "customBuild" => "ob-17325551",
        "dc" => "dc-apj",
        "clusterName" => "cluster-k8s",
        "style" => "fullInstall",
        "cpus" => 16, # 32 vCPUs
        "memory" => 32000, # 98000 98GB memory
        "fullClone" => true,
        "nics" => 3,
        "networks" => ["public"]
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
        "customBuild" => "ob-17327517",
        "dcName" => ["dc-apj"],
        "nics" => 2,
        "networks" => ["force_public","public"],
        "enableDrs" => true,
        "clusters" => [
          {
            "name" => "cluster-k8s",
            "dc" => "dc-apj",
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
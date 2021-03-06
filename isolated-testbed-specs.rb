require_relative './lib/ifconf.rb'

# Work in progress.. please use to test-bed-deploy-v2.rb

GB = 1 * 1024 * 1024 # in KB

# Define a vCenter cluster with the given properties.
def cluster(cluster)
  features = {
    'vsan' => true,
    'enableDrs' => true,
    'enableHA' => true,
  }

  return cluster.merge(features)
end

def esx(vc, dc, cluster, n)
    name = "esx-#{dc}-#{n}"
    return {
      'name' => name,
      'vc' => vc,
      'dc' => dc,
      'clusterName' => cluster,
  
      'style' => 'fullInstall',
      'desiredPassword' => 'ca$hc0w',
      'vmotionNics' => ['vmk0'],
      # Using first disk (40GB) for ESXi installation and local VMFS datastore. Two 50GB disks will be part of vSAN Capacity Tier.
      'disk' => [40 * GB, 50 * GB, 600 * GB],
     
      # Flash disk for vSAN Cache Tier
      'ssd' => [50 * GB],
     
      # Starting index of local disks which are free for VMFS creation. Setting it to 2 so that nimbus does not create VMFS on 50GB disks.
      'freeLocalLuns' => 2,
      'fullClone' => true,
      'cpuReservation' => 3000,
      'memoryReservation' => 1024,
      'cpus' => 16, # 32 vCPUs
      'memory' => 32000,# 98000 98GB memory
      'nics' => 4,
      'localDatastoreNamePrefix' => "#{name}-local-data-",
    }
end


def attach_to_network(obj, net)
    return obj.merge({ 'networks' => [net] })
end

def noop(esx)
    return esx
end



$testbed = proc do
    {
        'version' => 4,
        'name' => 'rfoe-multinet-testbed',
        

        # force_public -> bind to nimbus public network
    # public -> bind to isolated_network vxlan  192.168.111.0/24 GW 192.168.111.1 DNS 192.168.111.1
    # net.0 -> bind to isolated_network vxlan  192.168.112.0/24 GW 192.168.112.1 DNS 192.168.112.1
    # net.1 -> bind to isolated_network vxlan  192.168.113.0/24 GW 192.168.113.1 DNS 192.168.113.1

        'network' => [
            { 'name' => 'net.0', 'routable' => true },
            { 'name' => 'net.1', 'routable' => true },
        ],

        'vcs' => [
            attach_to_network({
                'name' => 'vc',
                'type' => 'vcva',
                'nics' => 2,
                'networks' => ['force_public']
                'additionalScript' => [],
                'dbType' => 'embedded',
                'dcName' => [
                    'datacenter',
                    'remote-site-1',
                    #'remote-site-2',
                    #'remote-site-3',
                    #'remote-site-4',
                ],
                'clusters' => [
                    cluster({ 'name' => 'cluster', 'dc' => 'datacenter'}),

                # cluster({ 'name' => 'cluster', 'dc' => 'remote-site-1'}),
                #{ 'name' => 'cluster', 'dc' => 'remote-site-2', 'vsan' => true },
                #{ 'name' => 'cluster', 'dc' => 'remote-site-3', 'vsan' => true },
                #{ 'name' => 'cluster', 'dc' => 'remote-site-4', 'vsan' => true },
                ],
            }, 'public')
        ],

        'esx' => [
            # Datacenter gets 3 hosts for minimum vSan quorum.
           
            attach_to_network(esx('vc', 'datacenter', 'cluster', 1), 'nsx::datacenter.0'),
            attach_to_network(esx('vc', 'datacenter', 'cluster', 2), 'nsx::datacenter.0'),
            attach_to_network(esx('vc', 'datacenter', 'cluster', 3), 'nsx::datacenter.0'),
        ],

        'vsan' => true,
        'worker' => [
            {
                "name" => "worker.0",
                "enableStaticIpService" => true, # turn on static ip server
            },
        ],

        'postBoot' => proc { |runId, testbedSpec, vmList, catApi, logDir|
            Log.info "testbedSpec\n#{testbedSpec}"
            Log.info "vmlist\n#{vmList}"

            Log.info "start installing traffic shaping"
            if_install_tools()
            if_install_traffic_shaping("100ms", "10mbit")
            Log.info "end installing traffic shaping"
        },
    
    }
end


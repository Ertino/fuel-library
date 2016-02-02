notice('MODULAR: keystone/workloads_collector_add.pp')

$workloads_hash   = hiera('workloads_collector', {})
$service_endpoint = hiera('service_endpoint')
$external_lb      = hiera('external_lb', false)
$ssl_hash         = hiera_hash('use_ssl', {})
$management_vip   = hiera('management_vip')

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

if $external_lb {
  Haproxy_backend_status<||> {
    provider => 'http',
  }
  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_url      = "${admin_identity_protocol}://${admin_identity_address}:35357"
}

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '200',
  step  => '6',
  url   => $external_lb ? {
    default => $haproxy_stats_url,
    true    => $admin_identity_url,
  },
} ->

class { 'openstack::workloads_collector':
  enabled               => $workloads_hash['enabled'],
  workloads_username    => $workloads_hash['username'],
  workloads_password    => $workloads_hash['password'],
  workloads_tenant      => $workloads_hash['tenant'],
  workloads_create_user => true,
}
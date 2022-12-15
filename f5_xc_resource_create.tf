resource "volterra_origin_pool" "op-ip-internal" {
  name                   = var.poolname
  //Name of the namespace where the origin pool must be deployed
  namespace              = var.namespace
  origin_servers {
   k8s_service {
     service_name = "athena-log4shell-demo.automation-waap-waf"
    
    
     vk8s_networks = true
    
    
     site_locator {
       virtual_site {
         tenant = "ves-io"
         namespace = "shared"
         name = "ves-io-all-res"
       }
     }
     
  }
    labels= {} 
  }
 no_tls = true
  port = "8080"
  endpoint_selection     = "LOCALPREFERED"
  loadbalancer_algorithm = "LB_OVERRIDE"
}

//End of the file
//==========================================================================
//Definition of the Load-Balancer, 2-https-lb.tf
//Start of the TF file
resource "volterra_http_loadbalancer" "lb-https-tf" {
  depends_on = [volterra_origin_pool.op-ip-internal]
  //Mandatory "Metadata"
  name      = var.lbname
  //Name of the namespace where the origin pool must be deployed
  namespace = var.namespace
  //End of mandatory "Metadata" 
  //Mandatory "Basic configuration" with Auto-Cert 
  domains = [var.lbdomain]
  https_auto_cert {
    add_hsts = true
    http_redirect = true
    no_mtls = true
    enable_path_normalize = true
    tls_config {
        default_security = true
      }
    port = "443"
  }
  default_route_pools {
      pool {
        name = var.poolname
        namespace = var.namespace
      }
      weight = 1
      priority = 1
    }
  //Mandatory "VIP configuration"
  advertise_on_public_default_vip = true
  //End of mandatory "VIP configuration"
  //Mandatory "Security configuration"
  no_service_policies = true
  no_challenge = true
  disable_rate_limit = true
  multi_lb_app = true
  user_id_client_ip = true
  //End of mandatory "Security configuration"
  //Mandatory "Load Balancing Control"
  source_ip_stickiness = true
  //End of mandatory "Load Balancing Control"
  
}

//End of the file
//==========================================================================

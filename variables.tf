variable "api_cert" {
            type = string
            default = "certificate-latest.cert"
        }
        
        variable "api_key" {
          type = string
          default = "private_key-latest.key"
        }
        
        variable "api_url" {
            type = string
            default = "https://treino.console.ves.volterra.io/api"
        }
        variable "namespace" {
            type = string
            default = "automation-waap-waf"
        }
        variable "lbdomain" {
            type = string
            default = "log4j2.f5-hyd-demo.com"
        }
        variable "lbname" {
            type = string
            default = "automation-log4j"
        }
        variable "poolname" {
            type = string
            default = "log4j-shell"
        }
        variable "WAFname" {
            type = string
            default = "waf-log4j"
        }

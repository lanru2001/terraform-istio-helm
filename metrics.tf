##########################################################################################################################################################
# Metrics server to check resource usage of the nodes and pods
##########################################################################################################################################################
resource "helm_release" "metrics_server" {
    name        = "metrics-server"
    repository  = "https://charts.bitnami.com/bitnami" 
    chart       = "metrics-server"
    namespace   = "kube-system"
    
    set {
        name  = "apiService.create"
        value = "true"
    }
}

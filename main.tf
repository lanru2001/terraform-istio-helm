########################################################################################################################################################
#1. Create AWS Load Balancer Controller
#AWS Load Balancer controller manages the Application Load Balancer and Target Group in AWS  to satisfy the configuration of  Kubernetes ingress objects
########################################################################################################################################################

resource "helm_release" "loadbalancer_controller" {

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts" 
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [ 
    aws_iam_role.lb_controller_role,
    kubernetes_service_account.service_account,
    aws_iam_policy.test_policy
  ]

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "enableServiceMutatorWebhook"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
    
}

######################################################################################
#2. Create Service Account for AWS Load Balancer Controller
######################################################################################

resource "kubernetes_service_account" "service_account" {
  depends_on = [ 
       aws_iam_role.lb_controller_role,
       aws_iam_policy.test_policy
  ]       
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/name" = "aws-load-balancer-controller"
        "app.kubernetes.io/component"= "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.lb_controller_role.arn}"
    }
  }
  
}

######################################################################################
#3. Create namespace for istio-system, dlframe and models
######################################################################################

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_namespace" "dlframe" {
  metadata {
    name = "dlframe"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_namespace" "models" {
  metadata {
    name = "models"
    labels = {
      istio-injection = "enabled"
    }
  }
}

######################################################################################
#4. Install Istio using public repository
######################################################################################

resource "helm_release"  "istio_base" {
  name       = "base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
  force_update = true
  version      = "1.17.1"

}

resource "helm_release"  "istio_istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  force_update = true
  version      = "1.17.1"

  set {
    name = "global.imagePullPolicy"
    value = "IfNotPresent"
  }

  set {
    name  = "defaultRevision"
    value = "default"
  }

  set {
    name  = "global.istioNamespace"
    value = "istio-system"
  }

  set {
    name  = "global.mtls.enabled"
    value = "false"
  }

  set {
    name  = "security.enableNamespacesByDefault"
    value = "false"
  }

  set {
    name  = "meshConfig.outboundTrafficPolicy"
    value = "ALLOW_ANY"
  }

  set {
    name  = "meshConfig.accessLogFile"
    value = "/dev/stdout"
  }

  depends_on = [ 
    helm_release.istio_base,
    helm_release.istio_istiod
  ]

}

# ######################################################################################
# #5. Install Istio ingress gateway
# ######################################################################################

resource "helm_release" "istio_ingress" {
  name              = "istio-ingressgateway"
  chart             = "gateway"
  repository        = "https://istio-release.storage.googleapis.com/charts" 
  namespace         = "istio-system"
  create_namespace  = true
  cleanup_on_fail   = true
  force_update      = false
  version           = "1.17.1"

  values = [
  <<-EOT
podAnnotations:
  inject.istio.io/templates: "gateway"
EOT
  ]

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "autoscaling.minReplicas"
    value = var.istio_ingress_min_pods
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = var.istio_ingress_max_pods
  }

  set {
    name  = "service.ports[0].name"
    value = "status-port"
  }

  set {
    name  = "service.ports[0].port"
    value = 15021
  }

  set {
    name  = "service.ports[0].targetPort"
    value = 15021
  }

  set {
    name  = "service.ports[0].nodePort"
    value = 30021
  }

  set {
    name  = "service.ports[0].protocol"
    value = "TCP"
  }


  set {
    name  = "service.ports[1].name"
    value = "http2"
  }

  set {
    name  = "service.ports[1].port"
    value = 80
  }

  set {
    name  = "service.ports[1].targetPort"
    value = 80
  }

  set {
    name  = "service.ports[1].nodePort"
    value = 30080
  }

  set {
    name  = "service.ports[1].protocol"
    value = "TCP"
  }


  set {
    name  = "service.ports[2].name"
    value = "https"
  }

  set {
    name  = "service.ports[2].port"
    value = 443
  }

  set {
    name  = "service.ports[2].targetPort"
    value = 443
  }

  set {
    name  = "service.ports[2].nodePort"
    value = 30443
  }

  set {
    name  = "service.ports[2].protocol"
    value = "TCP"
  }

  depends_on = [ 
    helm_release.istio_base,
    helm_release.istio_istiod,
    helm_release.metrics_server
  ]
}


# ######################################################################################
# #Install Istio egress gateway
# ######################################################################################
# resource "helm_release" "istio_egress" {
#   name       = "istio-egress"
#   chart      = "https://istio-release.storage.googleapis.com/charts" 
#   namespace  = "istio-system"
# }


######################################################################################
#6. Install istio gateway using kubectl_manifest
######################################################################################

resource "kubectl_manifest" "istio_gateway_dlframe" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: dlframe-gateway
  namespace: dlframe
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: http
      number: 80
      protocol: HTTP
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        # helm_release.istio_ingress      
    ]
}

resource "kubectl_manifest" "istio_gateway_models" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: models-gateway
  namespace: models
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: http
      number: 80
      protocol: HTTP
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        # helm_release.istio_ingress 
       
    ]
}

######################################################################################
#7.istio VirtualService
######################################################################################

resource "kubectl_manifest" "jwt_virtualservice" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: VirtualService 
metadata: 
  name: jwt-auth-vs
  namespace: dlframe
spec:
  gateways:
  - dlframe-gateway
  hosts:
  - jwt-auth.dev.dlframe.com
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: jwt-auth.dlframe.svc.cluster.local
        port:
          number: 9000
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models
    ]
}


resource "kubectl_manifest" "models-api_virtualservice" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata: 
  name: models-api-vs
  namespace: dlframe
spec:
  gateways:
  - dlframe-gateway
  hosts:
  - models-api.dev.dlframe.com
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: models-api.dlframe.svc.cluster.local
        port:
          number: 9000
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models
    ]
}


resource "kubectl_manifest" "k8s_api_virtualservice" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: k8s-api-vs
  namespace: dlframe
spec:
  gateways:
    - dlframe-gateway
  hosts:
    - k8s-api.dev.dlframe.com
  http:
    - match:
        - uri:
            prefix: /
      route:
        - destination:
            host: k8s-api.dlframe.svc.cluster.local
            port:
              number: 9000
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models
    ]
}


resource "kubectl_manifest" "inference_api_virtualservice" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: inference-api-vs
  namespace: dlframe
spec:
  gateways:
    - dlframe-gateway
  hosts:
    - inference-api.dev.dlframe.com
  http:
    - match:
        - uri:
            prefix: /
      route:
        - destination:
            host: inference-api.dlframe.svc.cluster.local
            port:
              number: 9000
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models
    ]
}

# ######################################################################################
# #8. istio DestinationRule
# ######################################################################################

#Models - sqprepid1
resource "kubectl_manifest" "jwt_auth_dr" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: jwt-auth-destinationrule
  namespace: dlframe
spec:
  host: jwt-auth.dlframe.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN

YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.jwt_virtualservice
    ]
}

resource "kubectl_manifest" "models_api-_dr" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: models-api-destinationrule
  namespace: dlframe
spec:
  host: models-api.dlframe.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.models-api_virtualservice
    ]
}

resource "kubectl_manifest" "k8s_api_dr" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: k8s-api-destinationrule
  namespace: dlframe
spec:
  host: k8s-api.dlframe.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.k8s_api_virtualservice
        
    ]
}

resource "kubectl_manifest" "inference_api_dr" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: inference-api-destinationrule
  namespace: dlframe
spec:
  host: inference-api.dlframe.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.inference_api_virtualservice
    ]
}

resource "kubectl_manifest" "sqprepid1_dr" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: sqprepid1-dr
  namespace: models
spec:
  host: sqprepid1.models.svc.cluster.local  
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.sqprepid1_virtualservice
    ]
}

resource "kubectl_manifest" "yolo_localization_dr" {
    yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: yolo-localization-occ-v06tl-dr 
  namespace: models
spec:
  host: yolo-localization-occ-v06tl.models.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
YAML
    depends_on = [ 
        # helm_release.istio_base,
        # helm_release.istio_istiod,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.yolo_localization_virtualservice
    ]
}

################################################################
#9. Istio-ingress
################################################################

resource "kubectl_manifest" "ingress" {
    yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: istio-ingress-2
  namespace: istio-system
  annotations:
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig":
      { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:060866400178:certificate/703dcf11-8357-4465-9162-db1c20565348
    alb.ingress.kubernetes.io/healthcheck-path: "/healthz/ready"
    alb.ingress.kubernetes.io/healthcheck-port: "31100"
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/subnets: subnet-25a08809,subnet-acfd4ecb,subnet-c81548c4,subnet-edcc34d2
    alb.ingress.kubernetes.io/security-groups: sg-079b741ff8602879c
    alb.ingress.kubernetes.io/scheme: internet-facing
    kubernetes.io/ingress.class: alb
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: ssl-redirect
            port:
              name: use-annotation
        path: /
        pathType: Prefix
      - backend:
          service:
            name: istio-ingressgateway
            port:
              number: 80
        path: /
        pathType: Prefix
YAML
    depends_on = [ 
        helm_release.istio_base,
        helm_release.istio_istiod,
        helm_release.loadbalancer_controller,
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.yolo_localization_virtualservice,
        aws_iam_role.lb_controller_role,
        kubernetes_service_account.service_account,
        aws_iam_policy.test_policy
    ]
}

###########################################################################################
#10. Authorization Policy
###########################################################################################

resource "kubectl_manifest" "istio_auth_policy" {
    yaml_body = <<YAML
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: dlframe-auth-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
  - to:
      - operation:
          hosts:
            - "grafana.dev.dlframe.com"
            - "prometheus.dev.dlframe.com"
      - operation:
          paths:
            - "/about"
            - "*/about"
            - "/jwt-auth/v1/jwks"
            - "/jwt-auth/v1/login"
            - "/jwt-auth/v1/loginByToken"
            - "/docs"
            - "/swagger/*"
YAML
    depends_on = [ 
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.yolo_localization_virtualservice
    ]
}

###########################################################################################
#11. Request Authentication
###########################################################################################

resource "kubectl_manifest" "istio_request_auth" {
    yaml_body = <<YAML
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: dlframe-authentication
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
    - issuer: "jwt-auth@dlframe.com"
      jwksUri: "https://jwt-auth.dev.dlframe.com/jwt-auth/v1/jwks"
      forwardOriginalToken: true
      fromHeaders:
        - name: "Authorization"
          prefix: "Bearer "
      outputClaimToHeaders:
        - header: "User-Email"
          claim: "user.email"
YAML
    depends_on = [ 
        kubectl_manifest.istio_gateway_dlframe,
        kubectl_manifest.istio_gateway_models,
        kubectl_manifest.yolo_localization_virtualservice
    ]
}

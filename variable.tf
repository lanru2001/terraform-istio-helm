variable "cluster_name" {
    default = "test-cluster"
}

variable "certificate_authority" {
    default = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJV3lRWkg4Q0tYemN3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpBNU1qSXhOekV4TXpOYUZ3MHpNekE1TVRreE56RXhNek5hTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURxaktYTnJCRkJoWTVJY1NKcEZCYzdRSTQzOHJDbUc3V3piTXcyZlJPODQ3TkV4alFsK05YTUNsQngKdWxpVG5tK0dqTDV6ZXV2NG1FTXExcWpVMC9VOTVycGlYdE5Vb1JscWY4dVQyY2svVHBSVlRIR1o0MXdlYXNRVApLaVVrVW9BRnNPMElkQnkvUjV2K041OFpvamZqeE00Si9XZmI3T1lyUTU5YnpRVk1aODErTGxXNDQ3VTRRb1NzCmxvMnc5SWNOYmw5Z0RrMVB1NFJvdlk5a25ROXNHVm5IdlBEYjA3OVhQYVgrTDlkVVVDRVh4OXJlbjJQTUtLUEgKYUVtWk8wSzVGUUdaOFRlSGRadW5LbjV0UERhRmlCNTdQS1RMbnVBMnJDdjMwdDloVVFLUGs3OGxRMW5DVWNNQQo4SUQzSGZGVFZqQWEzdHp0WDdSeHdFWkJ4bFd4QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTWjBSNXpWekpWOFc1WTNvMzBuMjVLOFlYUXFqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQnE2dVZVUlh6OApPL0V1RzdEeXNlTURWZFV5NW9DN0NVQU9Td1dEL3lQUTB4OTZQT1pJQm94M0RLd1hnbU1oaGdqZDZYUFR2NDFjCmxlRzhnTXFaWjg4emE2L2xZNkl1MFdJcFRGeFoyeTh0SWR5ZE1GTkwvOTloQUkvVGxsaVNmR3BVWTNKNENSeTAKemRqV2lBV0F5S1Rha2JtUEtYVTdIYVJHZkR1M0JmRFdiQlNua0tzNmQzcEpaV3J3b2hCeWlSV0I5b3JPbFNnOAo3M1JPWVB6aEZYSFlwWXlYaDFoalFFbldBK1l3MlJVbFhSV2xidXdWQnE4TW1MVkptVmlFUDVmZ29nMVZpYTJvCkY2Y1daN2orZjUxekZrZkVla0pxdHc0WmdKSDNlMWo5K1FwQm85aGk5S1ZXWTFpeHNDU1UrWFlMTFpnS0FxM3AKWWtWK3FIRjl4MDdyCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"

}

variable "cluster_endpoint" {
    default = "https://808CFAD241C84F694DD832D647398A97.gr7.us-east-1.eks.amazonaws.com"

} 

variable "open_connect_id" {
    default = "808CFAD241C84F694DD832D647398A97"  #id on the OpenID Connect provider URL - https://oidc.eks.us-east-1.amazonaws.com/id/81E8DA4D3363DBCAADA6FE6C4C860C2E
}

variable "vpc_id" {
  default = "vpc-91cac0e8"

}

variable "env_name" {
    default = "dev"
} 

variable "istio_ingress_min_pods" {
  type        = number
  default     = 1
  description = "Minimum pods for istio-ingress-gateway"
}

variable "istio_ingress_max_pods" {
  type        = number
  default     = 1
  description = "Maximum pods for istio-ingress-gateway"
}

variable "aws_region" {
    default = "us-east-1"
  
}

variable "account_id" {
    default = "060866400178"
  
}

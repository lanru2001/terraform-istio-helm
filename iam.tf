##########################################################################################################################################################
#1. IAM Role for AWS Load Balancer Controller 
##########################################################################################################################################################
resource "aws_iam_role" "lb_controller_role" {
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRoleWithWebIdentity"
                    Condition = {
                        StringEquals = {
                            "oidc.eks.${var.aws_region}.amazonaws.com/id/${var.open_connect_id}:aud" = "sts.amazonaws.com"
                            "oidc.eks.${var.aws_region}.amazonaws.com/id/${var.open_connect_id}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
                        }
                    }
                    Effect    = "Allow"
                    Principal = {
                        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/oidc.eks.${var.aws_region}.amazonaws.com/id/${var.open_connect_id}"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    #force_detach_policies = false
    managed_policy_arns   = [
        aws_iam_policy.test_policy.arn,
    ]
    name                  = "AWSLBControllerIAMRole"
    path                  = "/"
    tags                  = {
        "alpha.k8s.io/cluster-name"            = var.cluster_name
        "alpha.k8s.io/iamserviceaccount-name"  = "kube-system/aws-load-balancer-controller"
        "k8s.io/v1alpha1/cluster-name"         =  var.cluster_name
    }
   
}
##########################################################################################################################################################
#2. IAM Policy for AWS Load Balancer Controller 
##########################################################################################################################################################
resource "aws_iam_policy" "test_policy" {
    name      = "AWSLBControllerIAMPolicy"
    path      = "/"
    policy    = jsonencode(
        {
            Statement = [
                {
                    Action   = [
                        "iam:CreateServiceLinkedRole",
                        "ec2:DescribeAccountAttributes",
                        "ec2:DescribeAddresses",
                        "ec2:DescribeAvailabilityZones",
                        "ec2:DescribeInternetGateways",
                        "ec2:DescribeVpcs",
                        "ec2:DescribeSubnets",
                        "ec2:DescribeSecurityGroups",
                        "ec2:DescribeInstances",
                        "ec2:DescribeNetworkInterfaces",
                        "ec2:DescribeTags",
                        "ec2:GetCoipPoolUsage",
                        "ec2:DescribeCoipPools",
                        "elasticloadbalancing:DescribeLoadBalancers",
                        "elasticloadbalancing:DescribeLoadBalancerAttributes",
                        "elasticloadbalancing:DescribeListeners",
                        "elasticloadbalancing:DescribeListenerCertificates",
                        "elasticloadbalancing:DescribeSSLPolicies",
                        "elasticloadbalancing:DescribeRules",
                        "elasticloadbalancing:DescribeTargetGroups",
                        "elasticloadbalancing:DescribeTargetGroupAttributes",
                        "elasticloadbalancing:DescribeTargetHealth",
                        "elasticloadbalancing:DescribeTags",
                        "elasticloadbalancing:*",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
                {
                    Action   = [
                        "cognito-idp:DescribeUserPoolClient",
                        "acm:ListCertificates",
                        "acm:DescribeCertificate",
                        "iam:ListServerCertificates",
                        "iam:GetServerCertificate",
                        "waf-regional:GetWebACL",
                        "waf-regional:GetWebACLForResource",
                        "waf-regional:AssociateWebACL",
                        "waf-regional:DisassociateWebACL",
                        "wafv2:GetWebACL",
                        "wafv2:GetWebACLForResource",
                        "wafv2:AssociateWebACL",
                        "wafv2:DisassociateWebACL",
                        "shield:GetSubscriptionState",
                        "shield:DescribeProtection",
                        "shield:CreateProtection",
                        "shield:DeleteProtection",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
                {
                    Action   = [
                        "ec2:AuthorizeSecurityGroupIngress",
                        "ec2:RevokeSecurityGroupIngress",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
                {
                    Action   = [
                        "ec2:CreateSecurityGroup",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
                {
                    Action    = [
                        "ec2:CreateTags",
                    ]
                    Condition = {
                        Null         = {
                            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
                        }
                        StringEquals = {
                            "ec2:CreateAction" = "CreateSecurityGroup"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = "arn:aws:ec2:*:*:security-group/*"
                },
                {
                    Action    = [
                        "ec2:CreateTags",
                        "ec2:DeleteTags",
                    ]
                    Condition = {
                        Null = {
                            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
                            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = "arn:aws:ec2:*:*:security-group/*"
                },
                {
                    Action    = [
                        "ec2:AuthorizeSecurityGroupIngress",
                        "ec2:RevokeSecurityGroupIngress",
                        "ec2:DeleteSecurityGroup",
                    ]
                    Condition = {
                        Null = {
                            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = "*"
                },
                {
                    Action    = [
                        "elasticloadbalancing:CreateLoadBalancer",
                        "elasticloadbalancing:CreateTargetGroup",
                    ]
                    Condition = {
                        Null = {
                            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = "*"
                },
                {
                    Action   = [
                        "elasticloadbalancing:CreateListener",
                        "elasticloadbalancing:DeleteListener",
                        "elasticloadbalancing:CreateRule",
                        "elasticloadbalancing:DeleteRule",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
                {
                    Action    = [
                        "elasticloadbalancing:AddTags",
                        "elasticloadbalancing:RemoveTags",
                    ]
                    Condition = {
                        Null = {
                            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
                            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = [
                        "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                        "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
                    ]
                },
                {
                    Action   = [
                        "elasticloadbalancing:AddTags",
                        "elasticloadbalancing:RemoveTags",
                    ]
                    Effect   = "Allow"
                    Resource = [
                        "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                        "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                        "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                        "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
                    ]
                },
                {
                    Action    = [
                        "elasticloadbalancing:ModifyLoadBalancerAttributes",
                        "elasticloadbalancing:SetIpAddressType",
                        "elasticloadbalancing:SetSecurityGroups",
                        "elasticloadbalancing:SetSubnets",
                        "elasticloadbalancing:DeleteLoadBalancer",
                        "elasticloadbalancing:ModifyTargetGroup",
                        "elasticloadbalancing:ModifyTargetGroupAttributes",
                        "elasticloadbalancing:DeleteTargetGroup",
                    ]
                    Condition = {
                        Null = {
                            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = "*"
                },
                {
                    Action   = [
                        "elasticloadbalancing:RegisterTargets",
                        "elasticloadbalancing:DeregisterTargets",
                    ]
                    Effect   = "Allow"
                    Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
                },
                {
                    Action   = [
                        "elasticloadbalancing:SetWebAcl",
                        "elasticloadbalancing:ModifyListener",
                        "elasticloadbalancing:AddListenerCertificates",
                        "elasticloadbalancing:RemoveListenerCertificates",
                        "elasticloadbalancing:ModifyRule",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
            ]
            Version   = "2012-10-17"
        }
    )
}

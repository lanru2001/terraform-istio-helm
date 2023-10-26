Update iam.tf
Azeez Olanrewaju authored 1 month ago
045882a1
 Code owners
Assign users and groups as approvers for specific file changes. Learn more.
dlframe-terra
tf-istio-helm
iam.tf
iam.tf
11.01 KiB
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
220
221
222
223
224
225
226
227
228
229
230
231
232
233
234
235
236
237
238
239
240
241
242
243
244
245
246
247
248
249
250
251
252
253
254
255
256
257
258
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

# EKS Security Group Configuration Fixes

## Problem Analysis

Your current Terraform configuration had **security group misconfigurations** that caused cross-node networking issues:

### Issues Found:

1. **Mixed Security Group Management**: 
   - Custom cluster security group + EKS-managed node security groups
   - Rules didn't apply to all security groups used by nodes

2. **Incomplete Inter-Node Rules**:
   - `self = true` only worked within the same security group
   - Missing ICMP rules for basic connectivity
   - Missing comprehensive node-to-node communication

3. **Security Group Isolation**:
   - EKS-managed security group and custom security group couldn't communicate
   - Pods on different nodes (different security groups) couldn't reach each other

## Root Cause

```hcl
# PROBLEMATIC: Your current main.tf
cluster_security_group_id = aws_security_group.eks_cluster_sg.id  # Custom cluster SG
additional_security_group_ids = [aws_security_group.nodes_sg.id]  # Custom node SG

# PROBLEMATIC: Your current nodes-securitygroup.tf  
ingress {
  protocol = "-1"
  self     = true  # ← Only works within the SAME security group
}
```

**The Issue**: EKS creates its own security groups, and your `self = true` rule only applied to your custom security group, not the EKS-managed ones.

## Solutions (Choose One)

### Option 1: Use EKS-Managed Security Groups (RECOMMENDED)

Replace your `main.tf` with `main-improved.tf`:

**Benefits**:
- ✅ EKS handles all security group complexity
- ✅ Proper inter-node communication by default
- ✅ AWS best practices
- ✅ Less maintenance overhead

**Key Changes**:
```hcl
# Remove custom cluster security group override
# cluster_security_group_id = aws_security_group.eks_cluster_sg.id

# Add proper rules via EKS module
node_security_group_additional_rules = {
  ingress_self_all = {
    description = "Node to node all ports/protocols"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    type        = "ingress"
    self        = true
  }
  
  ingress_icmp = {
    description = "ICMP between nodes"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    type        = "ingress"
    cidr_blocks = [var.vpc_cidr]
  }
}
```

### Option 2: Fix Custom Security Groups

Use `nodes-securitygroup-fixed.tf` if you need custom security groups:

**Key Fixes**:
```hcl
# Allow traffic between custom and EKS-managed security groups
ingress {
  protocol                 = "-1"
  source_security_group_id = module.eks.node_security_group_id
}

# Add reciprocal rule to EKS security group
resource "aws_security_group_rule" "eks_nodes_to_custom_nodes" {
  source_security_group_id = aws_security_group.nodes_sg.id
  security_group_id        = module.eks.node_security_group_id
}
```

## Implementation Steps

### For Option 1 (Recommended):

1. **Backup current configuration**:
   ```bash
   cp main.tf main.tf.backup
   cp nodes-securitygroup.tf nodes-securitygroup.tf.backup
   ```

2. **Replace main.tf**:
   ```bash
   cp main-improved.tf main.tf
   ```

3. **Remove custom security group files**:
   ```bash
   # Comment out or remove these files:
   # - cluster-securitygroup.tf
   # - nodes-securitygroup.tf
   ```

4. **Apply changes**:
   ```bash
   terraform plan
   terraform apply
   ```

### For Option 2 (If you need custom security groups):

1. **Replace nodes security group**:
   ```bash
   cp nodes-securitygroup-fixed.tf nodes-securitygroup.tf
   ```

2. **Apply changes**:
   ```bash
   terraform plan
   terraform apply
   ```

## Verification

After applying fixes, verify cross-node communication:

```bash
# Test node-to-node ping
kubectl debug node/<node1> -it --image=busybox -- ping -c 3 <node2-ip>

# Test pod-to-pod communication
kubectl exec -n <namespace> <pod1> -- curl <service-name>.<namespace>.svc.cluster.local
```

## Security Group Rules Summary

### Required for EKS Cross-Node Communication:

1. **All Protocols (-1)**: Node-to-node communication
2. **ICMP**: Basic connectivity testing
3. **TCP 1025-65535**: Ephemeral ports for services
4. **TCP 53/UDP 53**: DNS resolution
5. **TCP 443**: Kubernetes API communication

### Current Working Rules (After Manual Fix):
```bash
# What we manually added to fix the issue:
aws ec2 authorize-security-group-ingress --group-id sg-061867f141c1f77b0 \
  --ip-permissions IpProtocol=icmp,FromPort=-1,ToPort=-1,UserIdGroupPairs=[{GroupId=sg-061867f141c1f77b0}]

aws ec2 authorize-security-group-ingress --group-id sg-061867f141c1f77b0 \
  --ip-permissions IpProtocol=-1,UserIdGroupPairs=[{GroupId=sg-061867f141c1f77b0}]
```

## Best Practices

1. **Use EKS-managed security groups** when possible
2. **Always test cross-node connectivity** after deployment
3. **Include ICMP rules** for troubleshooting
4. **Use security group references** instead of CIDR blocks for inter-node communication
5. **Document any custom security group requirements**

## Prevention Checklist

- [ ] Use EKS-managed security groups primarily
- [ ] Include comprehensive inter-node communication rules
- [ ] Test cross-node pod communication in CI/CD
- [ ] Add ICMP rules for troubleshooting
- [ ] Verify security group rule coverage for all protocols needed
- [ ] Document security group architecture decisions

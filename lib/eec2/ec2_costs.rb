module Ec2Costs

  # This data is as of 2017-04-23, and obtained from http://www.ec2instances.info/ (see below)
  COSTS = {
    'ap-northeast-1' => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'ap-northeast-2' => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'ap-south-1'     => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'ap-southeast-1' => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'ap-southeast-2' => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'ca-central-1'   => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'eu-central-1'   => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'eu-west-1'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'eu-west-2'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'sa-east-1'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'us-east-1'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'us-east-2'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'us-west-1'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
    'us-west-2'      => {'m1.small' => 0.044, 'm1.medium' => 0.087, 'm1.large' => 0.175, 'm1.xlarge' => 0.35, 'c1.medium' => 0.13, 'c1.xlarge' => 0.52, 'cc2.8xlarge' => 2, 'cg1.4xlarge' => 2.1, 'm2.xlarge' => 0.245, 'm2.2xlarge' => 0.49, 'm2.4xlarge' => 0.98, 'cr1.8xlarge' => 3.5, 'i2.xlarge' => 0.853, 'i2.2xlarge' => 1.705, 'i2.4xlarge' => 3.41, 'i2.8xlarge' => 6.82, 'hi1.4xlarge' => 3.1, 'hs1.8xlarge' => 4.6, 't1.micro' => 0.02, 't2.nano' => 0.0059, 't2.micro' => 0.012, 't2.small' => 0.023, 't2.medium' => 0.047, 't2.large' => 0.094, 't2.xlarge' => 0.188, 't2.2xlarge' => 0.376, 'm3.medium' => 0.067, 'm3.large' => 0.133, 'm3.xlarge' => 0.266, 'm3.2xlarge' => 0.532, 'g2.2xlarge' => 0.65, 'g2.8xlarge' => 2.6, 'm4.large' => 0.108, 'm4.xlarge' => 0.215, 'm4.2xlarge' => 0.431, 'm4.4xlarge' => 0.862, 'm4.10xlarge' => 2.155, 'm4.16xlarge' => 3.447, 'c4.large' => 0.1, 'c4.xlarge' => 0.199, 'c4.2xlarge' => 0.398, 'c4.4xlarge' => 0.796, 'c4.8xlarge' => 1.591, 'c3.large' => 0.105, 'c3.xlarge' => 0.21, 'c3.2xlarge' => 0.42, 'c3.4xlarge' => 0.84, 'c3.8xlarge' => 1.68, 'p2.xlarge' => 0.9, 'p2.8xlarge' => 7.2, 'p2.16xlarge' => 14.4, 'x1.16xlarge' => 6.669, 'x1.32xlarge' => 13.338, 'r4.large' => 0.133, 'r4.xlarge' => 0.266, 'r4.2xlarge' => 0.532, 'r4.4xlarge' => 1.064, 'r4.8xlarge' => 2.128, 'r4.16xlarge' => 4.256, 'r3.large' => 0.166, 'r3.xlarge' => 0.333, 'r3.2xlarge' => 0.665, 'r3.4xlarge' => 1.33, 'r3.8xlarge' => 2.66, 'i3.large' => 0.156, 'i3.xlarge' => 0.312, 'i3.2xlarge' => 0.624, 'i3.4xlarge' => 1.248, 'i3.8xlarge' => 2.496, 'i3.16xlarge' => 4.992, 'd2.xlarge' => 0.69, 'd2.2xlarge' => 1.38, 'd2.4xlarge' => 2.76, 'd2.8xlarge' => 5.52, 'f1.2xlarge' => 1.65, 'f1.16xlarge' => 13.2, },
  }

  def Ec2Costs.lookup(region, instance_type)
    COSTS[region][instance_type]
  end
end

# Originally I was using the Amazon Price List API, but that involved downloading a ~100MB JSON file, and
# and it was slow and awkward (even though I was caching it in ~/.aws).
# So instead, I now download CSV files for each region from http://www.ec2instances.info/
# (a pretty painstaking process) and then run this script, capturing the output:
if __FILE__ == $0
  require 'csv'

  puts 'COSTS = {'
  %w[
    ec2-ap-northeast-1.csv
    ec2-ap-northeast-2.csv
    ec2-ap-south-1.csv
    ec2-ap-southeast-1.csv
    ec2-ap-southeast-2.csv
    ec2-ca-central-1.csv
    ec2-eu-central-1.csv
    ec2-eu-west-1.csv
    ec2-eu-west-2.csv
    ec2-sa-east-1.csv
    ec2-us-east-1.csv
    ec2-us-east-2.csv
    ec2-us-west-1.csv
    ec2-us-west-2.csv
  ].each do |filename|
    print "  '#{filename.sub('ec2-', '').sub('.csv', '')}'=>{"
    CSV.foreach(filename, headers: true) do |row|
      printf "'#{row['API Name']}'=>#{row['Linux On Demand cost'].sub('$', '').sub(' hourly', '')},"
    end
    puts '},'
  end
  puts '}'
end

#from distutils import core
import os.path

from aws_cdk.aws_s3_assets import Asset

from aws_cdk import (
    # Duration,
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_s3 as s3,
    App as app,
    RemovalPolicy as rp,
    CfnOutput as aws_output,
    CfnParameter as param,
    #core as coreCdk,
)

# with open('./script/user_data_bastion.sh') as f:
#     user_data_bastion = f.read()


from constructs import Construct

dirname = os.path.dirname(__file__)

class CdkProxyServerStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        cdk_vpc = ec2.Vpc(self, 'cdk-server-vpc',nat_gateways=0,
        subnet_configuration=[
                ec2.SubnetConfiguration(name='public',subnet_type=ec2.SubnetType.PUBLIC)
            ]
        )

        # cdk_linux2 = ec2.MachineImage.latest_amazon_linux(
        #     generation=ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
        #     edition=ec2.AmazonLinuxEdition.STANDARD,
        #     virtualization=ec2.AmazonLinuxVirt.HVM,
        #     storage=ec2.AmazonLinuxStorage.GENERAL_PURPOSE
        # )

        private_bucket = s3.Bucket(
            self, 
            'cdk-server-keys',
            bucket_name='cdk-server-keys',
            versioned=True,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            encryption=s3.BucketEncryption.S3_MANAGED,
            auto_delete_objects=True,
            removal_policy=rp.DESTROY,
        )

        cdk_role = iam.Role(self,"cdk-server-role", assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"))

        cdk_role.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore"))

        cdk_sg = ec2.SecurityGroup(self, "cdk-server-sg",vpc=cdk_vpc)

        source_ip = param(self, "sourceIP",
            type="String",
            description="The public IP that your internet traffic comes from. Will be whitelisted and only traffic from here can access the VPN."
        )

        cdk_sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(source_ip.value_as_string),
            connection=ec2.Port.tcp(22),
            description="Ingress from Rouse",
        )

        cdk_sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(source_ip.value_as_string),
            connection=ec2.Port.udp(1194),
            description="VPN from Rouse",
        )

        cdk_instance = ec2.Instance(self, "cdk-server-instance",
            instance_type=ec2.InstanceType("t3.nano"),
            machine_image=ec2.MachineImage.latest_amazon_linux(),
            vpc=cdk_vpc,
            role=cdk_role,
            security_group=cdk_sg,
        )

        asset = Asset(self, "Asset", path=os.path.join(dirname, "configure.sh"))
        local_path = cdk_instance.user_data.add_s3_download_command(
            bucket=asset.bucket,
            bucket_key=asset.s3_object_key
        )

        # Userdata executes script from S3
        cdk_instance.user_data.add_execute_file_command(
            file_path=local_path
        )
        asset.grant_read(cdk_instance.role)
        private_bucket.grant_read_write(cdk_instance.role)

        aws_output(self, "Public_IP",
            value=cdk_instance.instance_public_ip,
            description="Public IP that you will use to access the VPN",
            export_name="us-west-1-IP"
        )
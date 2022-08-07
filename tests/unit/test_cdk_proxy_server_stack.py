import aws_cdk as core
import aws_cdk.assertions as assertions

from cdk_proxy_server.cdk_proxy_server_stack import CdkProxyServerStack

# example tests. To run these tests, uncomment this file along with the example
# resource in cdk_proxy_server/cdk_proxy_server_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = CdkProxyServerStack(app, "cdk-proxy-server")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })

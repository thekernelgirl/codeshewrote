#!/bin/python
import boto3
import graphviz

def generate_infrastructure_diagram():
    # Create a Boto3 client for AWS Resource Groups Tagging API
    client = boto3.client('resourcegroupstaggingapi')

    # Get all resources in the account
    response = client.get_resources()

    # Create a Graphviz graph object
    graph = graphviz.Digraph()

    # Iterate over each resource and add it to the graph
    for resource in response['ResourceTagMappingList']:
        resource_type = resource['ResourceARN'].split(':')[2]
        resource_id = resource['ResourceARN'].split(':')[5]

        # Add the resource to the graph
        graph.node(resource_id, label=f"{resource_type}\n{resource_id}")

        # Get the resource's dependencies
        dependencies = client.list_tags_for_resource(ResourceARN=resource['ResourceARN'])['Tags']

        # Add the dependencies as edges in the graph
        for dependency in dependencies:
            if dependency['Key'] == 'aws:cloudformation:stack-id':
                stack_id = dependency['Value']
                graph.edge(stack_id, resource_id)

    # Render and save the graph as a PNG image
    graph.format = 'png'
    graph.render('account_infrastructure_diagram')

# Call the function to generate the infrastructure diagram
generate_infrastructure_diagram()

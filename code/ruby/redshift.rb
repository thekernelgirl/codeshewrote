require 'aws-sdk-redshift'

# AWS credentials
Aws.config.update({
  region: 'your_region',
  credentials: Aws::Credentials.new('your_access_key_id', 'your_secret_access_key')
})

# Create Redshift client
redshift = Aws::Redshift::Client.new

# Define cluster parameters
cluster_params = {
  cluster_identifier: 'your_cluster_identifier',
  node_type: 'dc2.large', # Specify the node type based on your concurrency and latency requirements
  cluster_type: 'single-node', # Single-node for simplicity, can be 'multi-node' for more complex configurations
  number_of_nodes: 1, # Specify the number of nodes in the cluster (only applicable for multi-node clusters)
  publicly_accessible: true, # Specify if the cluster is publicly accessible
  master_username: 'your_master_username',
  master_user_password: 'your_master_password',
  # Add other parameters as needed
}

# Create Redshift cluster
begin
  resp = redshift.create_cluster(cluster_params)
  puts "Cluster #{resp.cluster_identifier} is being created."
rescue Aws::Redshift::Errors::ServiceError => e
  puts "Error creating cluster: #{e.message}"
end


```yaml
---
- name: Create DynamoDB table
  hosts: localhost
  gather_facts: false

  vars:
    region: us-west-2
    table_name: my_table
    stream_enabled: true
    cross_region_replication_enabled: true
    scaling_enabled: true

  tasks:
    - name: Create DynamoDB table
      aws_dynamodb_table:
        name: "{{ table_name }}"
        region: "{{ region }}"
        stream_enabled: "{{ stream_enabled }}"
        cross_region_replication_enabled: "{{ cross_region_replication_enabled }}"
        scaling_enabled: "{{ scaling_enabled }}"
        state: present
      register: result

    - name: Display table details
      debug:
        var: result
```

Make sure you have the `boto3` library installed on the machine where you are running Ansible. You can install it using the following command:

```
pip install boto3
```

Replace the values of `region`, `table_name`, `stream_enabled`, `cross_region_replication_enabled`, and `scaling_enabled` variables according to your requirements.

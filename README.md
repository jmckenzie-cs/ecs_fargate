# ecs_fargate

Quick Demo notes

To removed all managed sections of an ECS tasl before registration:

jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .registeredAt, .registeredBy, .compatibilities, .networkMode, .cpu, .memory)' task_definition.json > cleaned_task_definition.json

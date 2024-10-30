# Step 1: Get list of ECS Task definitions

aws ecs list-task-definitions

# Step 2: Download Task definition

aws ecs describe-task-definition --task-definition "task-definition-arn" --out json > task_definition.json


# Step 3: Clean up Task definition

jq '.taskDefinition | walk(if type == "object" then del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .registeredAt, .registeredBy, .compatibilities) else . end)' task_definition.json > cleaned_vulnapp_definition.json

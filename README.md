# How to retrieve a existing task definitionn and preform clean up 

## Step 1: Get list of ECS Task definitions
This command retrieves all ECS task definitions in your AWS account
```bash
aws ecs list-task-definitions
```

## Step 2: Download Task definition
Downloads the specific task definition using its ARN and saves it as a JSON file
```bash
aws ecs describe-task-definition --task-definition task-definition-arn --out json > task_definition.json
```

## Step 3: Clean up Task definition
Uses jq to remove unnecessary fields from the task definition JSON:
- taskDefinitionArn
- revision
- status
- requiresAttributes
- registeredAt
- registeredBy
- compatibilities

```bash
jq '.taskDefinition | walk(if type == "object" then del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .registeredAt, .registeredBy, .compatibilities) else . end)' task_definition.json > cleaned_vulnapp_definition.json
```

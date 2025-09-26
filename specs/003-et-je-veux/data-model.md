# Data Model: Automated Build on Feature/Task Addition

## Entities

### BuildResult
- **status**: Enum (Success, Failure)
- **Validation**: Status must be set based on presence of error messages.

### Feature
- **name**: String
- **Validation**: Non-empty name.

### Task
- **name**: String
- **Validation**: Non-empty name.

## Relationships
- BuildResult is generated after adding Feature or Task.
- No direct relationships between entities.

## State Transitions
- BuildResult: Created with Success or Failure after build execution.
# Tasks: Automated Build on Feature/Task Addition

**Input**: Design documents from `/specs/003-et-je-veux/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Validate task completeness:
   → All entities have models?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [x] T001 Create auto-build script in .specify/scripts/bash/auto-build.sh
- [x] T002 Integrate auto-build into create-new-feature.sh

## Phase 3.2: Core Implementation
- [x] T003 [P] BuildResult model in Resume-ATS/Models/BuildResult.swift
- [x] T004 BuildService in Resume-ATS/Models/BuildService.swift

## Phase 3.3: Integration
- [ ] No integration tasks required

## Phase 3.4: Polish
- [x] T005 Update docs for build automation in README.md

## Dependencies
- T003 blocks T004
- Implementation before polish (T005)

## Notes
- [P] tasks = different files, no dependencies
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks

2. **Ordering**:
   - Setup → Models → Services → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All entities have model tasks
- [x] Parallel tasks truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
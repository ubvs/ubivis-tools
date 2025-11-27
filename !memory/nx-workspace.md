# Nx Workspace Configuration

## Workspace Overview

**Workspace Name**: Ubivis
**Nx Version**: 22.0.2
**Nx Cloud ID**: 691102394bbe2d1653a6441e
**Cloud Status**: ✅ Connected and ready

## Workspace Structure

### Current Layout
```
mono/
├── packages/          # Workspace packages (npm workspaces)
│   └── .gitkeep      # Empty, ready for first package
├── .nx/              # Nx cache and metadata
├── nx.json           # Nx configuration
├── package.json      # Root package with workspaces
└── tsconfig.base.json # Shared TypeScript config
```

### Package Organization
- **Workspace Pattern**: `packages/*`
- **Import Scope**: `@ubivis/*`
- **No packages yet**: Ready for first generation

---

## Nx Configuration (nx.json)

### Named Inputs
Configuration for determining what files affect tasks:

```json
{
  "default": ["{projectRoot}/**/*", "sharedGlobals"],
  "production": ["default"],
  "sharedGlobals": ["{workspaceRoot}/.gitlab-ci.yml"]
}
```

**Explanation**:
- `default`: All files in project + shared global files
- `production`: Same as default (can be customized later)
- `sharedGlobals`: Changes to CI config affect all projects

### Plugins

#### @nx/js/typescript Plugin
**Status**: Active

**Targets Configured**:
1. **typecheck**: Type checking with TypeScript
2. **build**: Compilation (uses `tsconfig.lib.json`)
3. **build-deps**: Build project dependencies first
4. **watch-deps**: Watch mode for dependencies

**Plugin Options**:
```json
{
  "typecheck": {
    "targetName": "typecheck"
  },
  "build": {
    "targetName": "build",
    "configName": "tsconfig.lib.json",
    "buildDepsName": "build-deps",
    "watchDepsName": "watch-deps"
  }
}
```

---

## Task Orchestration

### Inferred Tasks
Nx automatically infers tasks from project configuration:
- TypeScript projects get `build`, `typecheck`, `build-deps`, `watch-deps`
- More tasks will be inferred as plugins are added

### Running Tasks

#### Single Project
```bash
npx nx <target> <project-name>
npx nx build my-app
npx nx test my-lib
```

#### Multiple Projects
```bash
# Run target for all projects
npx nx run-many -t build

# Run multiple targets
npx nx run-many -t lint test build

# Run with parallel execution
npx nx run-many -t test --parallel=3
```

#### Affected Projects Only
```bash
# Test only affected projects
npx nx affected -t test

# Build affected projects
npx nx affected -t build

# Compare against specific base
npx nx affected -t test --base=main
```

---

## Nx Cloud Integration

### Features Enabled
- ✅ Cloud ID configured: `691102394bbe2d1653a6441e`
- ✅ CI setup link available
- ✅ Distributed task execution ready (commented in CI)
- ✅ Self-healing CI with `nx fix-ci`

### CI Task Distribution
Currently commented out, can be enabled:
```bash
npx nx start-ci-run --distribute-on="3 linux-medium-js" --stop-agents-after="build"
```

### CI Recording
Record command logs to Nx Cloud:
```bash
npx nx-cloud record -- <command>
```

---

## Caching Strategy

### Local Caching
- **Location**: `.nx/cache/`
- **Automatic**: Enabled for all tasks by default
- **Based on**: File inputs, dependencies, configuration

### Remote Caching (Nx Cloud)
- **Status**: Available (Cloud ID configured)
- **Benefit**: Share cache across team and CI
- **Access**: Automatic when authenticated

### Cache Management
```bash
# Reset local cache
npx nx reset

# View cache stats
npx nx show
```

---

## Project Graph

### Current State
```json
{
  "graph": {
    "nodes": {},
    "dependencies": {}
  }
}
```
**Empty**: No projects created yet

### Viewing Graph
```bash
# Visual project graph (when projects exist)
npx nx graph

# Show project details
npx nx show project <project-name>

# Show task details
npx nx show project <project-name> --web
```

---

## TypeScript Integration

### Automatic Sync
Nx keeps TypeScript project references in sync with project graph:
- Runs automatically during `build` and `typecheck`
- Updates `tsconfig.json` references based on imports

### Manual Sync
```bash
# Sync references
npx nx sync

# Check if sync is needed (CI)
npx nx sync:check
```

### Base Configuration
**File**: `tsconfig.base.json`

**Key Settings**:
- Composite projects enabled
- Declaration maps for better IDE support
- Strict mode for type safety
- NodeNext modules (ESM)
- Custom conditions: `@ubivis/source`

---

## Workspace Commands

### Project Generation
```bash
# JavaScript/TypeScript library
npx nx g @nx/js:lib packages/<name>

# With options
npx nx g @nx/js:lib packages/<name> --publishable --importPath=@ubivis/<name>
```

### Release Management
```bash
# Version and release
npx nx release

# Dry run
npx nx release --dry-run

# Conventional commits
npx nx release --conventional-commits
```

### Workspace Maintenance
```bash
# List installed plugins
npx nx list

# Update Nx and plugins
npx nx migrate latest

# Format all files
npx nx format:write

# Check formatting
npx nx format:check
```

---

## Best Practices (from AGENTS.md)

### Task Execution
1. **Always use Nx commands** instead of direct tooling
2. **Prefer `nx run-many`** for multiple tasks
3. **Use `nx affected`** for efficient CI

### Workspace Management
1. **Use Nx MCP tools** for workspace analysis
2. **Use `nx_docs` tool** for configuration questions
3. **Check project graph** before making changes
4. **Use `nx_workspace` tool** for error debugging

### CI Pipeline
1. Retrieve CIPE details with `nx_cloud_cipe_details`
2. Fix failures with `nx_cloud_fix_cipe_failure`
3. Verify fixes by running the failed task

---

## Adding New Plugins

### Available Plugins
Can be added as needed:
- `@nx/angular`: Angular applications
- `@nx/react`: React applications
- `@nx/node`: Node.js applications
- `@nx/express`: Express APIs
- `@nx/nest`: NestJS applications
- `@nx/next`: Next.js applications
- `@nx/playwright`: E2E testing
- `@nx/jest`: Unit testing
- `@nx/eslint`: Linting
- `@nx/storybook`: Component documentation

### Installation
```bash
# Install plugin
npm install -D @nx/<plugin-name>

# Nx will auto-configure most plugins
```

---

## CI/CD Integration

### GitLab CI Configuration
**File**: `.gitlab-ci.yml`

**Current Tasks**:
```bash
npx nx run-many -t lint test build typecheck
```

**Features**:
- Runs on main branch and merge requests
- Interruptible jobs
- Self-healing with `nx fix-ci`
- Ready for distributed execution

### Environment
- Node 20 image
- CI=true environment variable
- Shared globals tracked in nx.json

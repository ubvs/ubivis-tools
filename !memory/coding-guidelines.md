# Coding Guidelines and Patterns

## Core Principles (from User Rules)

### 1. Iterate, Don't Reinvent
- **Always look for existing code** to iterate on
- Don't drastically change patterns without exhausting existing approaches
- Only introduce new patterns when absolutely necessary
- Remove old implementations after replacing them

### 2. Simplicity First
- **Prefer simple solutions** over complex ones
- Avoid over-engineering
- Keep solutions focused and minimal

### 3. DRY (Don't Repeat Yourself)
- **Check utils library** before creating duplicate code
- Look for similar functionality in other areas
- Extract common patterns to shared libraries

### 4. Environment Awareness
- Write code that works across **dev, test, and prod**
- Never mock data for dev or prod environments
- Only mock data in tests

### 5. Focused Changes
- Only make **requested or well-understood changes**
- Focus on relevant areas of code
- Don't touch unrelated code

---

## Code Organization

### File Size Limits
- **Max 200-300 lines** per file
- Refactor when approaching limit
- Split into smaller, focused modules

### No Disposable Scripts
- Avoid writing one-off scripts in files
- Use npm scripts or Nx tasks instead
- Keep codebase clean

### Project Structure
```
packages/
├── apps/              # Applications
│   ├── web/          # Frontend
│   └── api/          # Backend
├── libs/              # Shared libraries
│   ├── core/         # Core functionality
│   ├── types/        # TypeScript types
│   ├── utils/        # Utilities (check here first!)
│   ├── config/       # Configuration
│   └── constants/    # Constants
└── e2e/              # E2E tests
```

---

## Testing

### Test Coverage
- **Write thorough tests** for all major functionality
- Unit tests for business logic
- Integration tests for APIs
- E2E tests for user flows

### Test Data
- **Only mock data in tests**
- Never add stubbing to dev/prod code
- Use test fixtures and factories

---

## Environment Files

### .env Protection
- **Never overwrite .env** without asking first
- Confirm before making changes
- Use .env.example for templates

---

## Code Review Mindset

### Before Making Changes
1. **Understand existing patterns**
2. Check if similar code exists
3. Read related code areas
4. Consider side effects

### After Making Changes
1. **Think about impact** on other methods
2. Run affected tests
3. Check for breaking changes
4. Update related documentation

---

## Nx-Specific Guidelines

### Task Execution
- Use `nx run`, `nx run-many`, `nx affected`
- Never use underlying tools directly
- Leverage Nx cache and parallelization

### Project Organization
- Use workspace libraries for shared code
- Establish clear boundaries
- Follow Nx module boundaries (when configured)

---

## TypeScript

### Strict Mode
- All code must pass strict type checking
- No `any` types without justification
- Use proper interfaces and types

### Imports
- Use `@ubivis/*` scope for workspace imports
- Relative imports within same project
- Keep imports organized

---

## Bug Fixing

### Approach
1. **Find root cause**, not symptoms
2. Don't introduce new patterns hastily
3. Exhaust existing implementation options first
4. Add regression tests

### Pattern Changes
- Only change patterns after thorough evaluation
- Remove old implementation when replacing
- Document reasoning for changes

---

## Documentation

### When to Document
- New patterns or architectures
- Complex business logic
- Non-obvious solutions
- API interfaces

### What to Document
- Why, not just what
- Edge cases and limitations
- Environment considerations
- Dependencies and side effects

---

## Don'ts

❌ Don't mock data for dev/prod  
❌ Don't duplicate code without checking utils  
❌ Don't overwrite .env without permission  
❌ Don't touch unrelated code  
❌ Don't create disposable scripts in files  
❌ Don't exceed 300 lines per file  
❌ Don't introduce patterns without need  

---

## Do's

✅ Check for existing similar code  
✅ Write thorough tests  
✅ Keep files under 300 lines  
✅ Focus on task-relevant areas  
✅ Think about affected methods  
✅ Use simple solutions  
✅ Write environment-aware code  

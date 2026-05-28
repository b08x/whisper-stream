```markdown
# whisper-stream Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the development patterns, conventions, and workflows used in the `whisper-stream` repository. The codebase is written in TypeScript, with a focus on clear file organization, relative imports, and named exports. While no specific framework is detected, the repository follows consistent coding and testing practices that can be applied to similar TypeScript projects.

## Coding Conventions

### File Naming
- All files use **snake_case** for naming.
  - Example: `audio_processor.ts`, `stream_utils.ts`

### Import Style
- Use **relative imports** for modules within the project.
  - Example:
    ```typescript
    import { processAudio } from './audio_processor';
    ```

### Export Style
- Use **named exports** for all exported functions, types, or constants.
  - Example:
    ```typescript
    export function processAudio(input: Buffer): AudioResult { ... }
    ```

### Commit Patterns
- Commit messages are **freeform**, sometimes with prefixes.
- Average commit message length: ~53 characters.
  - Example:  
    ```
    Add initial implementation of audio streaming
    ```

## Workflows

### Adding a New Module
**Trigger:** When you need to add new functionality to the project  
**Command:** `/add-module`

1. Create a new file using snake_case (e.g., `new_feature.ts`).
2. Implement your functions using TypeScript.
3. Use named exports for all public functions or types.
4. Import dependencies using relative paths.
5. Add corresponding tests in a file named `new_feature.test.ts`.

### Running Tests
**Trigger:** When you want to verify the correctness of your code  
**Command:** `/run-tests`

1. Identify test files matching the pattern `*.test.*`.
2. Use the project's preferred test runner (framework is unknown; check project documentation or scripts).
3. Run all tests and review results.

### Refactoring Code
**Trigger:** When improving or reorganizing existing code  
**Command:** `/refactor`

1. Rename files using snake_case if needed.
2. Update relative imports to match new file paths.
3. Ensure all exports remain named.
4. Update or add tests as necessary.

## Testing Patterns

- Test files follow the `*.test.*` naming convention (e.g., `audio_processor.test.ts`).
- The testing framework is not specified; check for documentation or scripts in the repository.
- Tests should be placed alongside or near the modules they test.
- Example test file structure:
  ```typescript
  import { processAudio } from './audio_processor';

  describe('processAudio', () => {
    it('should process valid audio input', () => {
      // test implementation
    });
  });
  ```

## Commands
| Command        | Purpose                                      |
|----------------|----------------------------------------------|
| /add-module    | Scaffold and implement a new module          |
| /run-tests     | Run all tests in the repository              |
| /refactor      | Refactor code and update imports/exports     |
```

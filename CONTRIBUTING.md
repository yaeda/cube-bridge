# CONTRIBUTING.md

## Development Workflow

- Create a working branch before making any changes.
- All changes must be merged into `main` through a Pull Request.
- Do not commit directly to the `main` branch.
- Keep changes focused and avoid unrelated modifications.

## Specifications

- Project specifications must be documented in `docs/SPEC.md`.
- When implementing or changing behavior, check `docs/SPEC.md` first.
- If the implementation changes the expected behavior, update `docs/SPEC.md` as part of the same Pull Request.
- If the specification is unclear or missing, clarify it before implementation.

## Commit Messages

Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Examples:

```text
feat: add user profile page
fix: handle empty search results
test: add login validation tests
refactor: simplify API client
docs: update specification
```

## Test-Driven Development

Use Red/Green TDD as the default development approach.

1. Write a failing test first.
2. Confirm that the test fails for the expected reason.
3. Implement the minimum code needed to make the test pass.
4. Refactor while keeping all tests green.

## Before Creating a Pull Request

- Run the existing test suite when available.
- Run formatting and linting commands when available.
- Remove unnecessary debug logs or temporary code.
- Update documentation when behavior, usage, or specifications change.
- Ensure the Pull Request describes the purpose and scope of the change.

## General Guidelines

- Prefer small, reviewable changes.
- Preserve existing architecture and conventions unless there is a clear reason to change them.
- Ask for clarification before making large or ambiguous changes.
- Avoid introducing new dependencies unless necessary.

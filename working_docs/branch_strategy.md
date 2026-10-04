# Git Branching Strategy

## Branch Naming Convention

- **Feature Branches:** `feature/<feature-name>`
  - Example: `feature/database`, `feature/ui-shell`

- **Main Branch:** `main`
  - Production-ready code only

## Branch Creation

1. Always start from `main`
2. Create feature branch:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/<feature-name>
   ```

## Commit Convention

- Use conventional commits
- Format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Merge Strategy

- Feature branches merge into `main` via pull request
- Code review required
- All tests must pass

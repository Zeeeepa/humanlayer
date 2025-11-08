# Contributing to HumanLayer

Thank you for your interest in contributing to HumanLayer! We welcome contributions from the community.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Development Workflow](#development-workflow)
4. [Code Guidelines](#code-guidelines)
5. [Testing](#testing)
6. [Submitting Changes](#submitting-changes)

---

## Getting Started

### Prerequisites

Before contributing, make sure you have:
- ✅ Read the [README.md](README.md)
- ✅ Reviewed the [Code of Conduct](#code-of-conduct)
- ✅ Set up your development environment (see below)

### Ways to Contribute

- 🐛 **Report bugs** - Open an issue with reproduction steps
- ✨ **Suggest features** - Share your ideas via GitHub Discussions
- 📝 **Improve documentation** - Fix typos, add examples, clarify instructions
- 🔧 **Submit code** - Fix bugs or implement features
- 🧪 **Write tests** - Improve test coverage
- 🎨 **Enhance UI/UX** - Improve the desktop interface

---

## Development Setup

### Quick Setup

**Windows:**
```powershell
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer
powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
```

**Linux/macOS:**
```bash
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer
make setup
```

### Detailed Setup Guides

- **[Windows Deployment Guide](WINDOWS_DEPLOYMENT.md)** - Complete Windows setup
- **[Linux/macOS Deployment Guide](DEPLOYMENT.md)** - Unix-based systems
- **[Development Guide](DEVELOPMENT.md)** - Development workflows

### Running CodeLayer

**Start development environment:**
```bash
# Terminal 1: Start daemon
make daemon-dev

# Terminal 2: Start UI
make wui-dev
```

**Alternative (if `make` not available on Windows):**
```cmd
.\scripts\windows-start-dev.bat
```

When the Web UI launches in dev mode, you'll need to launch a managed daemon with it - click the 🐞 icon in the bottom right and launch a managed daemon.

---

## Development Workflow

### 1. Fork and Clone

```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/humanlayer.git
cd humanlayer

# Add upstream remote
git remote add upstream https://github.com/humanlayer/humanlayer.git
```

### 2. Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### 3. Make Changes

- Write clean, readable code
- Follow existing code style and conventions
- Add tests for new functionality
- Update documentation as needed

### 4. Test Your Changes

```bash
# Run linting and type checking
make check

# Run tests
make test

# Run both
make check-test
```

### 5. Commit Changes

Follow conventional commit format:

```bash
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug in session management"
git commit -m "docs: update deployment guide"
```

**Commit types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

### 6. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create a pull request on GitHub
```

### Claude Code Commands Cheat Sheet

When working with Claude Code sessions:

1. `/research_codebase` - Analyze codebase structure
2. `/create_plan` - Generate implementation plan
3. `/implement_plan` - Execute the plan
4. `/commit` - Commit changes
5. `gh pr create --fill` - Create pull request
6. `/describe_pr` - Generate PR description

---

## Code Guidelines

### General Principles

- ✅ **Write clear, self-documenting code**
- ✅ **Keep functions small and focused**
- ✅ **Add comments for complex logic**
- ✅ **Follow existing patterns in the codebase**
- ✅ **Prioritize readability over cleverness**

### Language-Specific Guidelines

#### TypeScript
- Use strict TypeScript configuration
- Prefer interfaces over types for object shapes
- Use async/await over promises
- Export types alongside implementations

#### Go
- Follow standard Go idioms
- Use context for cancellation
- Handle errors explicitly
- Write table-driven tests

#### React
- Use functional components with hooks
- Keep components small and reusable
- Use TypeScript for prop types
- Follow React best practices (no forwardRef in React 19)

### TODO Annotations

We use priority-based TODO annotations:

```typescript
// TODO(0): Critical - never merge
// TODO(1): High - architectural flaws, major bugs
// TODO(2): Medium - minor bugs, missing features
// TODO(3): Low - polish, tests, documentation
// TODO(4): Questions/investigations needed
// PERF: Performance optimization opportunities
```

---

## Testing

### Running Tests

**All tests:**
```bash
make test
```

**Specific components:**
```bash
make test-hld          # HLD daemon tests
make test-hlyr         # HLYR CLI tests
make test-wui          # WUI tests
make test-claudecode-go  # Claude Code Go SDK tests
```

**With verbose output:**
```bash
make test-verbose
```

### Writing Tests

- Write unit tests for new functions
- Add integration tests for complex workflows
- Use descriptive test names
- Test edge cases and error conditions
- Aim for high code coverage

**Example (Go):**
```go
func TestSessionCreate(t *testing.T) {
    // Arrange
    store := setupTestStore(t)
    defer store.Close()
    
    // Act
    session, err := store.CreateSession(ctx, params)
    
    // Assert
    require.NoError(t, err)
    assert.Equal(t, "running", session.Status)
}
```

**Example (TypeScript/Bun):**
```typescript
import { test, expect } from "bun:test";

test("creates session successfully", async () => {
  const session = await createSession({ prompt: "test" });
  expect(session.status).toBe("running");
});
```

### Pre-Push Hooks

Install git hooks to run checks automatically:

```bash
make githooks
```

This installs a pre-push hook that runs linting and tests before pushing.

---

## Submitting Changes

### Pull Request Guidelines

1. **Title**: Use conventional commit format
   ```
   feat: add session export functionality
   fix: resolve daemon crash on invalid input
   ```

2. **Description**: Include:
   - What changes were made
   - Why the changes were necessary
   - How to test the changes
   - Any breaking changes
   - Related issues (fixes #123)

3. **Size**: Keep PRs focused and reasonably sized
   - Split large changes into multiple PRs
   - One feature/fix per PR

4. **Tests**: Include tests for new functionality

5. **Documentation**: Update docs if needed

### PR Checklist

Before submitting:

- [ ] Code follows project style guidelines
- [ ] Tests pass locally (`make check-test`)
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] Commit messages follow conventional format
- [ ] PR description is clear and complete
- [ ] No merge conflicts with main branch

### Review Process

1. **Automated checks** run on your PR
2. **Maintainer review** - may request changes
3. **Address feedback** - make requested changes
4. **Approval** - maintainer approves PR
5. **Merge** - maintainer merges to main

### After Merge

- Delete your feature branch
- Pull latest changes from upstream
- Continue contributing! 🎉

---

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing private information
- Other unprofessional conduct

### Enforcement

Violations may result in:
- Warning
- Temporary ban
- Permanent ban

Report violations to: contact@humanlayer.dev

---

## Getting Help

### Resources

- **Documentation**: [README.md](README.md), [DEVELOPMENT.md](DEVELOPMENT.md)
- **Discord**: https://humanlayer.dev/discord
- **GitHub Issues**: https://github.com/humanlayer/humanlayer/issues
- **Email**: contact@humanlayer.dev

### Questions?

- Check existing issues and discussions
- Ask in Discord #help channel
- Open a GitHub Discussion
- Email the maintainers

---

## Recognition

Contributors are recognized in:
- Git commit history
- GitHub contributors page
- Release notes (for significant contributions)

Thank you for contributing to HumanLayer! 🚀

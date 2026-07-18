# Contributing to Project Name

Thank you for considering contributing to Project Name! We appreciate your time and effort to help make this project better.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [email@example.com].

## How Can I Contribute?

### Reporting Bugs

Before submitting a bug report:
- Check the [existing issues](https://github.com/username/project/issues) to avoid duplicates
- Ensure you're using the latest version
- Collect information about your environment

**To submit a good bug report:**
1. Use a clear, descriptive title
2. Describe the exact steps to reproduce
3. Provide specific examples
4. Describe the behavior you observed and expected
5. Include screenshots if applicable
6. Note your environment (OS, version, etc.)

### Suggesting Features

We welcome feature suggestions! To suggest a feature:
1. Check if it's already been suggested
2. Provide a clear use case
3. Explain why this would be useful to most users
4. Consider if this could be a plugin/extension instead

### Contributing Code

#### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/project-name.git
   cd project-name
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/username/project-name.git
   ```
4. Install dependencies:
   ```bash
   npm install
   # or
   pip install -e .[dev]
   # or
   cargo build
   ```
5. Run tests to verify setup:
   ```bash
   npm test
   # or
   pytest
   # or
   cargo test
   ```

#### Making Changes

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. Make your changes following our [code style](#code-style)

3. Add or update tests for your changes

4. Run tests locally:
   ```bash
   npm test
   ```

5. Commit your changes:
   ```bash
   git commit -m "Brief description of changes"
   ```
   See [commit message guidelines](#commit-messages) below.

6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

7. Open a Pull Request

#### Pull Request Process

Before submitting a pull request:

- [ ] Code follows the project style guide
- [ ] Tests pass locally
- [ ] New code has tests
- [ ] Documentation is updated (if needed)
- [ ] Commit messages are clear and follow conventions
- [ ] Branch is up-to-date with main

**PR Description should include:**
- What changed and why
- Related issue numbers (if any)
- Screenshots (for UI changes)
- Any breaking changes

**What happens next:**
1. Maintainers will review your PR
2. You may be asked to make changes
3. Once approved, your PR will be merged
4. Your contribution will be included in the next release!

## Code Style

### General Guidelines

- Write clear, readable code
- Add comments for complex logic
- Keep functions small and focused
- Use descriptive variable names

### Language-Specific Style

**JavaScript/TypeScript:**
- Use ESLint configuration provided
- Run `npm run lint` to check
- Run `npm run format` to auto-format with Prettier

**Python:**
- Follow PEP 8
- Use Black for formatting: `black .`
- Check with flake8: `flake8`
- Type hints for public APIs

**Rust:**
- Follow Rust style guidelines
- Run `cargo fmt` before committing
- Run `cargo clippy` and fix warnings

## Commit Messages

Use clear, conventional commit messages:

```
type(scope): brief description

Longer explanation if needed (wrap at 72 characters)

Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style/formatting (no functional changes)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(parser): add support for new syntax

fix(api): handle null values in response

docs(readme): update installation instructions
```

## Testing

All code contributions must include tests.

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- path/to/test.js

# Run with coverage
npm run test:coverage
```

### Writing Tests

- Place tests next to code: `feature.test.js`
- Use descriptive test names
- Test happy path and edge cases
- Aim for 80%+ code coverage

**Test structure:**
```javascript
describe('FeatureName', () => {
  it('should handle valid input', () => {
    // Arrange
    const input = 'valid';

    // Act
    const result = feature(input);

    // Assert
    expect(result).toBe('expected');
  });

  it('should throw on invalid input', () => {
    expect(() => feature(null)).toThrow();
  });
});
```

## Documentation

Update documentation when you:
- Add new features
- Change existing behavior
- Fix bugs that affect usage
- Add configuration options

**What to update:**
- README.md - User-facing features
- API documentation - Function signatures, parameters
- Inline comments - Complex logic
- Changelog - User-visible changes

## Getting Help

Need help contributing?
- 💬 [Discussions](https://github.com/username/project/discussions) - Ask questions
- 📖 [Documentation](https://docs.example.com) - Read the docs
- 💡 [Good First Issues](https://github.com/username/project/labels/good-first-issue) - Beginner-friendly tasks

## Recognition

Contributors will be:
- Listed in the [Contributors](https://github.com/username/project/graphs/contributors) page
- Mentioned in release notes for significant contributions
- Added to AUTHORS file (if applicable)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project ([MIT](LICENSE)).

---

**Note:** This is a basic CONTRIBUTING template suitable for small to medium projects. It includes:
- Code of Conduct reference
- Bug reporting guidelines
- Development setup steps
- Pull request process
- Code style guidelines
- Commit message conventions
- Testing requirements

For larger projects, consider adding:
- Architecture overview
- Release process
- Governance structure
- Contributor ladder
- Security policy details
- Multiple contribution types (translation, design, etc.)

Thank you for contributing! 🎉

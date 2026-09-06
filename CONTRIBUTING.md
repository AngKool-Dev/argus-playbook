# Contributing

Thank you for your interest in contributing to Argus Windows Playbook.

## Code of Conduct

Be respectful. Be constructive. We're all here to make Windows better.

## How to Contribute

### Reporting Bugs

- Use the GitHub issue tracker
- Include Windows version, build number, and AME Wizard version
- Describe the expected vs actual behavior
- Include logs from `C:\ProgramData\ArgusPlaybook\`

### Suggesting Features

- Open a GitHub issue with the `enhancement` label
- Describe the use case and expected behavior
- Explain why it fits the project's philosophy

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run `.\validate.ps1` and ensure it passes
5. Test on a VM if possible
6. Commit with a clear message
7. Push to your fork
8. Open a Pull Request

## Development Setup

1. Clone the repository
2. Install 7-Zip or NanaZip
3. Run `.\validate.ps1` to verify structure
4. Run `.\build.ps1` to create a test `.apbx`

## Testing

- Always test in a VM before submitting
- Take a snapshot before applying the playbook
- Test idempotency (run twice)
- Test restoration after application
- Document your test results

## Style Guide

### YAML
- Use 2-space indentation
- Use `!actionType:` with parameters on separate lines
- Include `title` and `description` for every file
- Comment liberally

### PowerShell
- Use approved verbs
- Include error handling
- Log all operations
- Use `Write-Host` with `[OK]`, `[WARN]`, `[ERROR]` prefixes

### Commit Messages
- Use present tense ("Add feature" not "Added feature")
- Use imperative mood
- First line under 50 characters
- Reference issues and PRs

## Architecture

See [README.md](README.md) for the project architecture overview.

## Questions?

Open an issue with the `question` label.

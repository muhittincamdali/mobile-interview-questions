# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in any code example or find that
a recommended practice in this repository is insecure, please report it
responsibly.

### How to Report

1. **Do not** open a public issue
2. Email the maintainer or use GitHub's private vulnerability reporting
3. Include a description of the issue and steps to reproduce

### What to Expect

- Acknowledgment within 48 hours
- A fix or update within 7 days for critical issues
- Credit in the changelog (unless you prefer anonymity)

## Scope

This repository contains interview questions and answers. Security concerns
typically involve:

- Insecure code examples that could be copy-pasted into production
- Outdated security practices recommended in answers
- Exposed secrets or credentials in examples

## Best Practices

All code examples in this repository should follow security best practices:

- No hardcoded credentials or API keys
- Proper input validation in examples
- Secure networking practices (HTTPS, certificate pinning)
- Safe data storage patterns (Keychain, encrypted storage)

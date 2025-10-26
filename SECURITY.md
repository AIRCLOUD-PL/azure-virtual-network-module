# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in this Terraform module, please report it to our security team.

### How to Report

1. **Do not create a public GitHub issue** for security vulnerabilities
2. Email security@aircloud.pl with details
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Initial Response**: Within 24 hours
- **Vulnerability Assessment**: Within 72 hours
- **Fix Development**: Within 1-2 weeks for critical issues
- **Public Disclosure**: After fix is deployed

## Security Best Practices

This module implements several security best practices:

- **Encryption**: All sensitive data is encrypted at rest and in transit
- **Access Control**: Implements principle of least privilege
- **Monitoring**: Comprehensive logging and monitoring capabilities
- **Compliance**: Supports various compliance frameworks (CIS, NIST, etc.)

## Security Scanning

We use automated tools to scan for vulnerabilities:

- **Checkov**: Infrastructure as Code security scanning
- **TFLint**: Terraform linting and best practices
- **Trivy**: Container and IaC vulnerability scanning

## Contact

For security-related questions: security@aircloud.pl

# Security Policy

## Supported Versions

The following versions of DreamWeaver are currently being supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within DreamWeaver, please send an email to the project maintainer. All security vulnerabilities will be promptly addressed.

**Please do not report security vulnerabilities through public GitHub issues.**

### Contact Information

- **Email**: zvarazoku9@icloud.com
- **GitHub**: [@BRMilev22](https://github.com/BRMilev22)

### When reporting, please include:

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** of the vulnerability
4. **Suggested fix** (if you have one)

## Response Timeline

- **Initial Response**: Within 48 hours of receiving the report
- **Status Update**: Within 7 days with either a fix timeline or explanation
- **Resolution**: Security fixes will be prioritized and released as soon as possible

## Security Measures

DreamWeaver implements several security measures to protect user data:

### Data Protection
- **Row Level Security (RLS)** implemented in Supabase database
- **User authentication** through Supabase Auth
- **Input validation** and sanitization on all user inputs
- **API key protection** with secure storage practices

### Authentication & Authorization
- Secure user registration and login processes
- Session management through Supabase Auth
- User data isolation through database policies

### API Security
- Secure communication with Mistral AI API
- API key rotation capabilities
- Rate limiting considerations

### Database Security
- PostgreSQL Row Level Security policies
- Encrypted connections to Supabase
- Regular security updates and patches

## Best Practices for Users

To ensure the security of your DreamWeaver installation:

1. **Keep dependencies updated** - Regularly update Swift packages and dependencies
2. **Secure API keys** - Store API keys securely and never commit them to version control
3. **Use strong passwords** - Ensure user accounts use strong, unique passwords
4. **Monitor access** - Regularly review user access and permissions in your Supabase dashboard

## Security Updates

Security updates will be released as needed and announced through:
- GitHub repository releases
- Repository README updates
- Direct communication to users when critical

## Acknowledgments

We appreciate the security research community and encourage responsible disclosure of any security vulnerabilities found in DreamWeaver.

---

**Note**: This security policy applies to the DreamWeaver iOS application and its associated backend services. For issues related to third-party services (Supabase, Mistral AI), please refer to their respective security policies.
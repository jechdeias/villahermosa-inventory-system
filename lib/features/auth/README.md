---
🔐 AUTH FEATURE

STATUS: ACTIVE

FEATURE RESPONSIBILITY:
User authentication and session management including:
- Login screen with role-based access
- Authentication state management
- Session handling and token management
- Role-based navigation routing

CURRENT STATE:
- Mixed implementation: real login_screen.dart + placeholder files
- Working authentication UI with core service integration
- Placeholder files for new architecture migration

WHERE NEW WORK SHOULD HAPPEN:
✅ Extend existing login_screen.dart (working implementation)
✅ Implement new auth features in screens/ folder
✅ Use viewmodels/ for state management
✅ Use widgets/ for reusable auth components

ARCHITECTURE:
- screens/ - Login, registration, password reset
- widgets/ - Reusable auth input components
- viewmodels/ - Authentication state management

Rules:
- UI only (no business logic)
- Role-based access control integration
- Secure authentication flows
- Session management
---

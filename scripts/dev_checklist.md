# Development Checklist

## Before Writing Code
- [ ] Review database schema documentation
- [ ] Run `flutter packages pub run build_runner build --delete-conflicting-outputs`
- [ ] Check generated companion signatures
- [ ] Run `flutter analyze` to ensure clean slate

## During Development
- [ ] Use TypeValidator utilities for ID conversions
- [ ] Follow naming conventions from schema docs
- [ ] Test each method individually before integration
- [ ] Run `flutter analyze` after each major change

## Database Operations
- [ ] Use correct ID types (UUID vs Integer)
- [ ] Validate foreign key existence
- [ ] Handle null values properly
- [ ] Use proper Value() wrappers for optional fields

## Testing
- [ ] Test with sample data
- [ ] Test edge cases (null, empty, invalid types)
- [ ] Verify sync status updates
- [ ] Test error handling

## Before Commit
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Check for type mismatches
- [ ] Update documentation if needed

## Common Pitfalls to Avoid
1. **Type Mismatches**: Always check if a field expects String UUID or Integer ID
2. **Value Wrappers**: Required fields don't need Value(), optional fields do
3. **Foreign Keys**: Use UUID strings for cross-table references
4. **Null Safety**: Always handle nullable fields properly
5. **Sync Status**: Don't forget to update sync_status for changes

## Quick Reference Commands
```bash
# Regenerate database code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Check for issues
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

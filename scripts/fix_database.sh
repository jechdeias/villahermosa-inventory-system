#!/bin/bash

# Database Fix Script
# Run this when you encounter database type issues

echo "🔧 Fixing database issues..."

# Step 1: Clean and regenerate
echo "📦 Cleaning and regenerating database code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Step 2: Check for analysis issues
echo "🔍 Running analysis..."
flutter analyze

# Step 3: Run tests if they exist
if [ -d "test" ]; then
    echo "🧪 Running tests..."
    flutter test
fi

echo "✅ Database fix complete!"
echo ""
echo "📋 Next steps:"
echo "1. Check for any remaining analysis errors"
echo "2. Fix any type mismatches using the patterns in docs/database_schema.md"
echo "3. Use TypeValidator utilities for new code"
echo "4. Follow the checklist in scripts/dev_checklist.md"

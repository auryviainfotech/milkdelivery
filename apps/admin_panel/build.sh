#!/bin/bash
set -e

echo "=== Starting Flutter Web Build ==="

# 1. Install Flutter
FLUTTER_VERSION="3.24.0"
echo "Installing Flutter $FLUTTER_VERSION..."

if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$(pwd)/flutter/bin"

# 2. Setup Flutter
echo "Setting up Flutter..."
flutter --version
flutter config --enable-web
flutter doctor -v

# 3. Create .env file from Vercel Environment Variables
echo "Creating .env file..."
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_URL=$SUPABASE_URL" > .env
    echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
    echo ".env file created successfully"
else
    echo "WARNING: Environment variables not set!"
fi

# 4. Get dependencies
echo "Getting dependencies..."
flutter pub get

# 5. Build the web app
echo "Building Flutter Web App..."
flutter build web --release --web-renderer html

echo "=== Build Complete ==="
ls -la build/web/

#!/bin/bash

# 1. Install Flutter if not present
if [ -d "flutter" ]; then
    cd flutter && git pull && cd ..
else
    git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Setup Flutter
./flutter/bin/flutter doctor
./flutter/bin/flutter config --enable-web

# 3. Create .env file from Vercel Environment Variables
echo "Creating .env file..."
printf "SUPABASE_URL=$SUPABASE_URL\nSUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" > .env

# 4. Build the web app
echo "Building Flutter Web App..."
./flutter/bin/flutter build web --release

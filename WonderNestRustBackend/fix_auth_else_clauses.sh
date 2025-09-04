#!/bin/bash

cd /Users/patrykpoborca/Documents/personal_projects/wonder_nest/WonderNestRustBackend

echo "Fixing auth.rs else clauses..."

# Remove the else clauses that are no longer needed after removing (&req) checks
sed -i '' '/} else {/,+4d' src/routes/v1/auth.rs

echo "Fixed auth.rs else clauses"
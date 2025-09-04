#!/bin/bash

# Fix remaining handler signatures in analytics.rs
cd /Users/patrykpoborca/Documents/personal_projects/wonder_nest/WonderNestRustBackend

# Fix get_weekly_overview
sed -i '' 's/req: Request,/AuthClaims(claims): AuthClaims,/g' src/routes/v1/analytics.rs

# Fix the claims extraction pattern
sed -i '' 's/let claims = (&req)\.ok_or_else(|| {/let _claims_check = \&claims;/g' src/routes/v1/analytics.rs
sed -i '' '/tracing::warn!("No family context in token");/d' src/routes/v1/analytics.rs
sed -i '' '/AppError::BadRequest("No family context in token"\.to_string())/d' src/routes/v1/analytics.rs
sed -i '' '/})?;/d' src/routes/v1/analytics.rs

echo "Analytics handlers fixed"
#!/bin/bash

# Fix file_upload.rs handler signatures - Request needs to come last in the extraction order

cat << 'EOF' > /tmp/fix_pattern.pl
#!/usr/bin/perl
use strict;
use warnings;

my $content = do { local $/; <> };

# Fix upload_file - swap req and multipart order
$content =~ s/async fn upload_file\(\s*State\((_state)\): State<AppState>,\s*req: Request,\s*mut multipart: Multipart,/async fn upload_file(
    State($_1): State<AppState>,
    mut multipart: Multipart,
    req: Request,/g;

# Fix other functions - move req to the end
$content =~ s/async fn (\w+)\(\s*State\((_\w+)\): State<AppState>,\s*req: Request,\s*Path\((\w+)\): Path<String>,/async fn $1(
    State($2): State<AppState>,
    Path($3): Path<String>,
    req: Request,/g;

# Fix functions with Query params
$content =~ s/async fn list_files\(\s*State\((_state)\): State<AppState>,\s*req: Request,\s*Query\((params)\): Query<FileQueryParams>,/async fn list_files(
    State($_1): State<AppState>,
    Query($2): Query<FileQueryParams>,
    req: Request,/g;

print $content;
EOF

chmod +x /tmp/fix_pattern.pl
perl /tmp/fix_pattern.pl < src/routes/v1/file_upload.rs > /tmp/file_upload_fixed.rs
mv /tmp/file_upload_fixed.rs src/routes/v1/file_upload.rs

echo "Fixed file_upload.rs handler signatures"
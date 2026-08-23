# Changelog

## [Unreleased]
### Added
- `scripts/create-b2-rclone-key.sh` — mints a write-only B2 application key (`listBuckets,listFiles,writeFiles,deleteFiles`, no `readFiles`) scoped to a single bucket, for use as `B2_ACCOUNT`/`B2_KEY`.
- `--all-buckets` option on the script to mint an account-wide key instead, for setups backing up to multiple buckets.
- README documentation and usage examples for the key-creation script, including the tradeoffs of `--all-buckets`.

### Changed
- `scripts/create-b2-rclone-key.sh` now parses the `b2 key create` output and prints the key ID and application key as clearly labeled `B2_ACCOUNT`/`B2_KEY` values, instead of leaving them as two unlabeled strings.

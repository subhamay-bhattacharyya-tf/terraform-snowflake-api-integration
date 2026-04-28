# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0 (2026-02-25)

### ⚠ BREAKING CHANGES

* Module source path changed from modules/snowflake-warehouse to root

- Move module files to repository root
- Update examples to reference root module
- Update CI workflow paths and semantic-release plugins
- Update provider source to snowflakedb/snowflake
- Add standardized header comments to all Terraform files
- Rename repository references to terraform-snowflake-module-template
* add blank line for improved readability in main.tf

### Features

* add blank line for improved readability in main.tf ([f5fa01d](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/f5fa01d9194dd7f87e7205dac7d7e8d0b709fab4))
* clean up legacy configurations and update CI workflows ([66cc322](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/66cc32266b94c5d035f63f5b0d508e4cd8ae6f1b))
* convert to single-module repository layout ([f865ae7](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/f865ae748217045b084d470456c3ad68e825658b))
* **snowflake-warehouse:** support multiple warehouses via map configuration ([fc62535](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/fc62535a424e12f43a9a8ece9cb7181952f3cbf4))
* update CI workflow to use snowflake-warehouse module and clean up main.tf ([9cb1a77](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/9cb1a7767180cae38e4c0a052382bad67a96c74e))

### Bug Fixes

* **release:** force patch release ([237e143](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/237e14302b4ae13c83f831ebf327ebdfb595e24d))
* **release:** trigger semantic release ([dd4234d](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/dd4234d0523788cf9014404cff8251d1f8714607))
* **snowflake:** update JWT authenticator to SNOWFLAKE_JWT and remove extra blank line ([1069d20](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-module-template/commit/1069d20cb9aa25f30eb69d770b3e7fc406194f44))

## [unreleased]

### 🚀 Features

- *(snowflake-warehouse)* Support multiple warehouses via map configuration
- Clean up legacy configurations and update CI workflows
- [**breaking**] Add blank line for improved readability in main.tf
- Update CI workflow to use snowflake-warehouse module and clean up main.tf
- [**breaking**] Convert to single-module repository layout

### 🐛 Bug Fixes

- *(snowflake)* Update JWT authenticator to SNOWFLAKE_JWT and remove extra blank line
- *(release)* Force patch release
- *(release)* Trigger semantic release

### 🚜 Refactor

- Restructure project to modular Terraform architecture
- *(test)* Migrate to gosnowflake config builder for JWT authentication
- *(test)* Improve warehouse property fetching and remove extra blank line

### 📚 Documentation

- *(readme)* Update badges to reflect Snowflake focus
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]

### 🎨 Styling

- *(snowflake-warehouse)* Add periods to output descriptions
- *(snowflake-warehouse)* Add blank line after module header comment
- *(main.tf)* Remove extra blank line for consistency

### ⚙️ Miscellaneous Tasks

- *(github-actions)* Add permissions and token for changelog generation
- *(release)* Version 1.0.0 [skip ci]
- *(testing)* Migrate from Jest to Terratest and restructure examples
- *(github-actions)* Migrate authentication to key-pair and remove property tests
- *(github-actions)* Enhance Terratest output visibility and remove conditional gate
- *(test)* Update Go dependencies and add go.sum
- *(testing)* Migrate to key-pair authentication and add go mod tidy
- *(github-actions)* Add pipefail option to Terratest commands and update Snowflake provider source
- *(release)* Version 1.0.1 [skip ci]

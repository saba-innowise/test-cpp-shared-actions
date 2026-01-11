# Shared GitHub Actions

This repository contains GitHub Actions that are called from the main `test-cpp` repo.
Two workflows exported here are `cpp-lint.yaml` and `cpp-build-test.yaml`.
First one is used to check formatting of the pull requests.
Second one is more versatile, it builds the project using `conan create`
with all the necessary options enabled to run the unit tests while doing so.
It also has an option to publish to the package registry which is utilized during both
the `publish` lable handling and releasing after merging accordingly labeled pull requests.

# Branch Protection

Branch protection rules are set up using the `setup-branch-protection.sh` script.
It ensures that the main branch has the following rules in place:
- Require pull request before merging
- Require successful linting, building, and testing
- Require branches to be up-to-date
- Require linear history
- Restrict force pushes
- Restrict deletions

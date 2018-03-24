# How to Make a Release

In order:

1. Update `CHANGELOG.md`, changing the "Unreleased" section to the next version
   identifier, in brackets, followed by the date in ISO 8601 format separated
   by a dash character. For example: `[0.9.9] - 2018-02-28` for version 0.9.9
   released on February 28, 2018.
2. Update `README.md`, changing the version in the installation instructions to
   the latest version.
3. Update `SwiftProjection.podspec`, updating the spec version.
4. Make a git commit with the previous three changes.
5. Tag the new commit with the version number prefixed with a 'v'. From the
   previous example, `v0.9.9`.
6. Push master and the new tag: `git push --tags origin master`
7. Travis is configured to build, test (and if it passed) push the update
   through CocoaPods Trunk.

## Manually pushing to CocoaPods

Instead of Step 7 above, you can also do it manually with `pod trunk push`.
This is assuming `pod trunk register` has been configured already.

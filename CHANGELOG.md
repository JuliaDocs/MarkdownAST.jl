# MarkdownAST.jl changelog

## Unreleased

* ![Feature][badge-feature] Implemented `replace` and `replace!` to safely mutate trees in arbitrary ways, and `empty!(node.children)` to remove all the children of a node
* ![Bugfix][badge-bugfix] The `getproperty` and `setproperty!` methods no longer print unnecessary debug log. ([#19][github-19])

## Version `v0.1.1`

* ![Bugfix][badge-bugfix] `append!` and `prepend!` methods now correctly append nodes from a `node.children` iterator. ([#16][github-16])

## Version `v0.1.0`

Initial release.

<!-- issue link definitions -->
[github-16]: https://github.com/JuliaDocs/MarkdownAST.jl/pull/16
[github-19]: https://github.com/JuliaDocs/MarkdownAST.jl/pull/19
<!-- end of issue link definitions -->

[markdownast]: https://github.com/JuliaDocs/MarkdownAST.jl

[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/bugfix-purple.svg
[badge-security]: https://img.shields.io/badge/security-black.svg
[badge-experimental]: https://img.shields.io/badge/experimental-lightgrey.svg
[badge-maintenance]: https://img.shields.io/badge/maintenance-gray.svg

<!--
# Badges

![BREAKING][badge-breaking]
![Deprecation][badge-deprecation]
![Feature][badge-feature]
![Enhancement][badge-enhancement]
![Bugfix][badge-bugfix]
![Security][badge-security]
![Experimental][badge-experimental]
![Maintenance][badge-maintenance]
-->


pkg-versions-tree
=================


Strategy
--------

This is an attempt at using `npm ls` for the tree scanning.

### Advantages

* It's usually faster, mostly because the JSON reading part is kept in RAM
  rather than running a subprocess for each package.


### Drawbacks

* The scan may be less thorough though.
* The tree is built by logical dependency, which may differ vastly from
  the file system structure.



Usage
-----

In the root of your (global or project's) `node_modules` directory,
run `treescan.sh` by its absolute path, or symlink, or similar method.










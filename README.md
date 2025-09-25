
<!--#echo json="package.json" key="name" underline="=" -->
npm-package-inventory-scanner-2509-pmb
======================================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Scan and report all the npm package names and versions in all `node_modules`
directories in parts of your local filesystem, to help find known-bad
versions.
<!--/#echo -->



⚠ Important Caveats ⚠
---------------------

* In case of git repos, only the worktree is scanned!
  (Usually, this means your currently checked-out branch,
  with any uncommited changes.)



Installation
------------

* For the JSON handing, you need to install the `jq` command.
  On Ubuntu, it should be available as Debian packae `jq`.



Usage
-----

### Scan package versions

In your project directory, run `scan_installed_packages.sh`
by its absolute path, or symlink, or similar method.

* In addition to the current working directory (i.e. your project),
  the scanner also tries to find other `node_modules` directories
  that node.js could search, but this feature isn't reliable yet.
  * If you want to skip global `node_modules` directories because you've
    already scanned them, you can specify CLI option `--no-global`.


### Check the inventory list for known bad versions

In `extra/pkglists/known-bad/` you can find downloaders
for some lists of known bad npm package versions,
that you can then compare with your inventory list.



Known issues
------------

* See also: Chapter "Important Caveats" above.
* Needs more/better tests and docs.





<!--#toc stop="scan" -->

&nbsp;


License
-------
<!--#echo json="package.json" key="license" -->
ISC
<!--/#echo -->

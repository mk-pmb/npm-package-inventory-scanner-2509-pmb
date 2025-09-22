
Packages infected with Shai-Hulud
=================================

Several websites have lists of packages infected with the Shai-Hulud worm:

<!-- versions table sites -->

* [Aikido: S1ngularity/nx attackers strike again](
  https://www.aikido.dev/blog/s1ngularity-nx-attackers-strike-again)
* [GetSafety: "Shai-Hulud" NPM attack runs malicious GitHub Action](
  https://www.getsafety.com/blog-posts/shai-hulud-npm-attack)
* [StepSecurity: ctrl/tinycolor and 40+ NPM Packages Compromised](
  https://www.stepsecurity.io/blog/ctrl-tinycolor-and-40-npm-packages-compromised)

<!-- / -->

The `download.sh` script will generate a file `tmp.versions.grep`
that you can use to grep your scanned packages list:

```text
$ grep --fixed-strings --file=tmp.versions.grep -- ../../../../../tmp.found.pkg
```

If there are no results, either you're safe or something went wrong with the
file formats.

To see if you had a close call, you can try to match just the names of
affected packages:

```text
$ grep --fixed-strings --file=tmp.names.grep -- ../../../../../tmp.found.pkg
```



Known issues
------------

* The version lists may have blind spots, for example:
  * 2025-09-22: `@art-ws/db-context`: GetSafety only lists v2.0.21
    as affected, while Aikido and StepSecurity only have v2.0.24.
    Intermediate versions may have existed but are now removed from npm.


















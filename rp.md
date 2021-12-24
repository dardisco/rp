# rp - R packages

*Author:* C. Dardis <christopherdardis@gmail.com><br>
*Version:* 0.1<br>
*URL:* [http://github.com/dardisco/rp](http://github.com/dardisco/rp)<br>

Building and checking an `R` package can be tedious and
typically requires a variety of tools, both within `R` and on
the command line.
The `rp` package aims to do the needful with a single function!

The package assumes that you are using the following workflow:
- Writing an `R` package that follows best practice guidelines
 for submission to CRAN.
- Using `roxygen2` for package documentation.
- Using `bash` for shell commands.  This *may* work with other
shell types.
 
On calling the function `rp-rp`, Emacs will open a new buffer
to display output from R and shell processes.
The functions on `rp-function-sequence` are then run.
This performs the following steps:
- Ensure `R` is the latest stable version (update if necessary)
- Ensure all `R` packages are the latest version.  This can
  take a long time if you have many packages!
- Use `roxygen2` to  update the package documentation.
  Note that you will still need to update the following files,
  as necessary:
  * DESCRIPTION
  * NEWS
  * README.md
  * The package documentation file e.g. `packageName.R` which
    has a line in `roxygen` format like "#' @docType package".
- Build the package using `R CMD build`.
  This will take place in the parent directory of the package.
- Check the package using `R CMD check --as-cran`.
- If `rp-check-rud` is `t`, also check the package with
  `R Under development`.  This is the latest,
  unstable, release of `R`.  This last step is not recommended
  routinely but typically should be performed once it has passed
  all of the package checks performed by the stable version of `R`.

### Installation

This package can be installed using

    (package-install-file "/path/to/rp.el")

Or place the folliwng in your init.el file:

    (add-to-list 'load-path "~/path/to/directory")
    (require 'rp)

### Usage

To start the process use the `rp-rp` command, e.g. with
    <kbd>M-x mp-mp RET</kbd>
This command should be called within the directory tree of
the `R` package. E.g. this can be called from a buffer which is a file
 in the package or from a `dired` buffer which is in the package.

Many of the functions in the package can be called independently.
For example, you may wish to run `rp-check-examples` before
going through the whole sequence, as this is a common source
of ERRORs and WARNINGs.

### For developers

Function-local/temporary variables are named using
as name1 e.g. `v1`, `buffer1`.



---
Converted from `rp.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).

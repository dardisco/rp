;;; rp.el --- R packages. -*- lexical-binding:t -*-

;; Copyright 2021-2022 - Chris Dardis

;; Author: C. Dardis <christopherdardis@gmail.com>

;; Version: 0.1

;; Keywords: R, Sweave, knitr, latex, noweb, bash
;; URL: http://github.com/dardisco/rp

;; This program is free software: you can redistribute
;;  it and/or modify it under the terms of the
;;  GNU General Public License as publishe
;;  the Free Software Foundation, either version 3
;;  of the License, or (at your option) any later version.
;; This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;; You should have received a copy of the GNU
;;  General Public License along with this program.
;; If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Building and checking an `R' package can be tedious and
;; typically requires a variety of tools, both within `R' and on
;; the command line.
;; The `rp' package aims to do the needful with a single function!
;;
;; The package assumes that you are using the following workflow:
;; - Writing an `R' package that follows best practice guidelines
;;  for submission to CRAN.
;; - Using `roxygen2' for package documentation.
;; - Using `bash' for shell commands.  This *may* work with other
;; shell types.
;; 
;; On calling the function `rp-rp', Emacs will open a new buffer
;; to display output from R and shell processes.
;; The functions on `rp-function-sequence' are then run.
;; This performs the following steps:
;; - Ensure `R' is the latest stable version (update if necessary)
;; - Ensure all `R' packages are the latest version.  This can
;;   take a long time if you have many packages!
;; - Use `roxygen2' to  update the package documentation.
;;   Note that you will still need to update the following files,
;;   as necessary:
;;   * DESCRIPTION
;;   * NEWS
;;   * README.md
;;   * The package documentation file e.g. `packageName.R' which
;;     has a line in `roxygen' format like "#' @docType package".
;; - Build the package using `R CMD build'.
;;   This will take place in the parent directory of the package.
;; - Check the package using `R CMD check --as-cran'.
;; - If `rp-check-rud' is `t', also check the package with
;;   `R Under development'.  This is the latest,
;;   unstable, release of `R'.  This last step is not recommended
;;   routinely but typically should be performed once it has passed
;;   all of the package checks performed by the stable version of `R'.
;;
;;; Installation:
;;
;; This package can be installed using
;;
;; (package-install-file "/path/to/rp.el")
;;
;; Or place the folliwng in your init.el file:
;;
;; (add-to-list 'load-path "~/path/to/directory")
;; (require 'rp)
;;
;;; Usage:
;;
;; To start the process use the `rp-rp' command, e.g. with
;;     `M-x mp-mp RET'
;; This command should be called within the directory tree of
;; the `R' package. E.g. this can be called from a buffer which is a file
;;  in the package or from a `dired' buffer which is in the package.
;;
;; Many of the functions in the package can be called independently.
;; For example, you may wish to run `rp-check-examples' before
;; going through the whole sequence, as this is a common source
;; of ERRORs and WARNINGs.
;;
;;; For developers:
;; 
;; Function-local/temporary variables are named using
;; as name1 e.g. `v1', `buffer1'.
;;

;;; Code:

(defun rp-rp ()
  "Run the list of functions in `rp-function-sequence'."
  (interactive)
  (pop-to-buffer "*R-package*")
  (erase-buffer)
  (dolist (x rp-function-sequence)
    (funcall x)))

(defcustom rp-function-sequence
  '(rp-update-R
    rp-roxy-write-doc
    rp-check-examples
    rp-build-package
    rp-check-package)
  "This `list' defines the functions to be called when `rp-rp' is called."
  :type '(list)
  :group 'rp)

(defgroup rp nil
  "R package.
This is a series of variables and functions to simplity
 the process of building and checking an R package
 for submission to CRAN."
  :prefix "rp-"
  :version 0.1)

(defun rp-update-R ()
  "Update R and packages, if necessary."
  (interactive)
  (rp-shell-sentinel "Rscript -e 'if(!(require(installr)))
    install.packages(\'installr\', dependencies=TRUE)
suppressWarnings(installr::updateR(GUI=FALSE))'")
  (rp-shell-sentinel
   "Rscript -e 'update.packages(ask=FALSE, instlib=.libPaths()[1])'"))

(defun rp-shell-sentinel (COMMAND)
  "Run COMMAND as a shell process and pause until done.
Output appears in buffer '*R-package*'."
  (lexical-let
      ((buffer1 "*R-package*")
       (command1 COMMAND))
    (pop-to-buffer buffer1)
    (set-process-sentinel
     (start-process-shell-command
      buffer1 buffer1 command1)
     (lambda (process1 event1)
       (if (= 0 (process-exit-status process1))
	   (progn
	     (message 
	      (concat "rp-shell-sentinel, with COMMAND "
		      command1 " ... done"))
	     (throw 'exit nil))
	 (progn
	   (message
	    (concat
	     "Error in rp-shell-sentinel, with COMMAND "
	     command1))))))
    (recursive-edit)))

(defun rp-roxy-write-doc ()
  "Use roxygen to write documentation.
Uses .R files with roxygen markup to create .Rd help files."
  (interactive)
  (let* ((description1 (rp-get-DESCRIPTION))
	 (package1 (rp-get-package-name description1))
	 (command1
	  (concat
	   "Rscript -e \"setwd('"
	   (concat
	    (rp-get-DESCRIPTION-parent description1)
	    "')
if(!(require(roxygen2)))
    install.packages('roxygen2', dependencies=TRUE)
roxygen2::roxygenize('"
	    package1
	    "')\" "))))
    (rp-shell-sentinel command1)))

(defun rp-get-DESCRIPTION-parent (DESCRIPTION)
  "Get name of parent directory of DESCRIPTION."
  (file-name-directory
   (directory-file-name
    (file-name-directory DESCRIPTION))))

(defun rp-get-DESCRIPTION ()
  "Get the DESCRIPTION file for a package.
Search upwards from the `default-directory' to find the first
file named DESCRIPTION."
  (interactive)
  (catch 'done
    (let ((d1
	   (car
	    (directory-files
	     default-directory t "^DESCRIPTION$"))))
      (unless d1
	(setq d1
	      (locate-dominating-file
	       (if (buffer-file-name)
		   (buffer-file-name)
		 default-directory)
	       "DESCRIPTION")))
      (when d1
	(setq d1
	      (car
	       (directory-files d1 t "^DESCRIPTION$"))))
      (unless d1
	(message "No DESCRIPTION file on this directory tree")
	(throw 'done nil))
      (setq d1 (file-truename d1))
      (message (prin1-to-string d1))
      d1)))

(defun rp-get-package-name (DESCRIPTION)
  "Get the package name from the DESCRIPTION file."
  (interactive)
  (find-file DESCRIPTION)
  (search-forward "package: " nil t)
  (let ((pn1 (buffer-substring-no-properties
	      (point) (line-end-position))))
    (replace-regexp-in-string " " "" pn1)
    (kill-buffer (buffer-name))
    pn1))

(defun rp-get-version (DESCRIPTION)
  "Get the version from the DESCRIPTION file."
  (interactive)
  (find-file DESCRIPTION)
  (search-forward "version: " nil t)
  (let ((vn1
	 (buffer-substring-no-properties
	  (point) (line-end-position))))
    (replace-regexp-in-string " " "" vn1)
    (kill-buffer (buffer-name))
    vn1))

(defun rp-check-examples ()
  "Check package examples using devtools."
  (interactive)
  (let* ((description1 (rp-get-DESCRIPTION))
	 (package1 (rp-get-package-name description1))
	 (command1
	  (concat
	   "Rscript -e \"setwd('"
	   (concat
	    (rp-get-DESCRIPTION-parent description1)
	    "')
if(!(require(devtools)))
    install.packages('devtools', dependencies=TRUE)
devtools::run_examples('"
	    package1
	    "')\" "))))
    (rp-shell-sentinel command1)))

(defun rp-build-package ()
  "Build package using R CMD build."
  (interactive)
  (let* ((description1 (rp-get-DESCRIPTION))
	 (package1 (rp-get-package-name description1))
	 (command1
	  (concat
	   "cd "
	   (rp-get-DESCRIPTION-parent description1)
	   " && R CMD build "
	   package1)))
    (rp-shell-sentinel command1)))

(defun rp-check-package ()
  "Check package.
Checks a tarball, e.g. as built by `rp-build-package'.
Uses R CMD check --as-cran.
If `rp-check-rud' is `t', also check with R Under development."
  (interactive)
  (let* ((description1 (rp-get-DESCRIPTION))
	 (package1 (rp-get-package-name description1))
	 (version1 (rp-get-version description1))
	 (command1
	  (concat
	   "cd "
	   (rp-get-DESCRIPTION-parent description1)
	   " && R CMD check --as-cran "
	   package1
	   "_"
	   version1
	   ".tar.gz")))
    (rp-shell-sentinel command1)	
    (when rp-check-rud
      (rp-update-rud)
      (setq command1 
	    (concat
	     "cd "
	     (rp-get-DESCRIPTION-parent description1)
	     " && "
	     rp-path-to-rud
	     "bin/R CMD check --as-cran "
	     package1
	     "_"
	     version1
	     ".tar.gz"))
      (rp-shell-sentinel command1))))

(defcustom rp-check-rud nil
  "Also check package with 'R Under development'?"
  :type '(radio 
	  (const :doc "No" :value nil)
	  (const :doc "Yes" :value t))
    :group 'rp)

(defcustom rp-path-to-rud "$HOME/rud/"
  "The path to install 'R Under development'?"
  :type '(directory)
  :group 'rp)

(defun rp-update-rud ()
  "Update 'R Under development', the development version of R."
  (interactive)
  (let ((ov1
	 (string-to-number
	  (shell-command-to-string
	   "svn info https://svn.r-project.org/R/trunk |
grep --regexp='Revision' |
	  grep --only-matching --regexp='[0-9]\\+'")))
	(lv1
	 (string-to-number
	  (shell-command-to-string
	   "command -v 'rud' && rud --version |
grep --only-matching --regexp='r[0-9]\\+' |
	grep --only-matching --regexp='[0-9]\\+'"))))
    (when (< lv1 ov1)
      (rp-shell-sentinel
       (concat "mkdir --parents " rp-path-to-rud))
      (rp-shell-sentinel
       (concat
	"svn checkout https://svn.r-project.org/R/trunk "
	rp-path-to-rud))       
      (write-region
       rp-rud-sh nil
	(concat
	 rp-path-to-rud "rud.sh" nil))
      (rp-shell-sentinel
       (concat
	"source " rp-path-to-rud "rud.sh")))))

(defcustom rp-rud-sh
  (concat "R_PAPERSIZE=letter 				
R_BATCHSAVE='--no-save --no-restore' 		
R_BROWSER=xdg-open				
PAGER=/usr/bin/pager				
PERL=/usr/bin/perl				
R_UNZIPCMD=/usr/bin/unzip			
R_ZIPCMD=/usr/bin/zip				
R_PRINTCMD=/usr/bin/lpr				
LIBnn=lib					
AWK=/usr/bin/awk                                
CC='ccache gcc'					
CFLAGS='-ggdb -pipe -std=gnu99 -Wall -pedantic' 
CXX='ccache g++'				
CXXFLAGS='-ggdb -pipe -Wall -pedantic' 		
FC='ccache gfortran'	 	  		
F77='ccache gfortran'				
MAKE='make -j4'					
./configure --prefix=" rp-path-to-rud " --enable-R-shlib --with-blas --with-lapack --with-readline --without-recommended-packages
make
make install")
  "Shell script to install R Under development."
  :type '(string)
  :group 'rp)

(defun rp-log ()
  "Open the log file."
       (interactive)
       (pop-to-buffer "*R-package*")
       (goto-char
	(point-max))
       (let
	   ((log1 (search-backward-regexp "for details.$" nil t)))
	 (when log1
	   (setq log1
		(replace-regexp-in-string
		 "[ ‘’\n]" ""
		 (buffer-substring-no-properties
		 (point) (line-end-position -1))))
	   (insert-file-contents log1))))

(provide 'rp)

;;; rp.el ends here

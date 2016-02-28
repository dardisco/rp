(defun rp-hook ()
  ;; (define-key ess-mode-map (kbd "RET") #'rp-ret)
  (define-key ess-mode-map (kbd "<return>") #'rp-ret)
  (define-key ess-mode-map [(ctrl return)] #'rp-start-R)
  ;; (define-key ess-mode-map (kbd "M-P") #'rp-previous-input)
  (define-key ess-mode-map [(meta shift p)] #'rp-previous-input))

(add-hook 'ess-mode-hook #'rp-hook)

(defun rp-ret () "h"
       (interactive)
       (if (not
	    (char-equal
	     (char-after (line-beginning-position)) (string-to-char "#")))
	   (newline-and-indent)
	 (progn
	   (let (p1 p2 pref1)
	     (save-excursion
	       (beginning-of-line)
	       (search-forward-regexp "#*\\|'" (line-end-position) t)
	       (search-forward "'" (line-end-position) t)
	       (set 'p2 (point))
	       (set 'pref1
		    (buffer-substring-no-properties (line-beginning-position) p2)))
	     (newline)
	     (insert (concat pref1 " "))
	     (indent-for-tab-command)))))

(defun rp-start-R (&optional NEW) "h"
       (interactive)
       (unless (eq (count-windows) 2)
	 (delete-other-windows)
	 (split-window-right))
       (let (cb1 p1 lRProc)
	 (set 'cb1 (current-buffer))
	 (when (buffer-file-name)
	   (if (featurep 'ess)
	       (ess-save-and-set-local-variables)
	     (save-buffer)))
	 (set 'p1 (rp-get-Rproc NEW))
	 (set-window-buffer (window-at 1 1) cb1)
	 (display-buffer-use-some-window (process-buffer p1) nil)
	 (rp-send-line-or-region p1)))

(defun rp-get-Rproc (&optional NEW) "h"
       (interactive)
       (let (p1 lRProc)
	 (when NEW
	 (set 'p1 (rp-new-Rproc)))
	 (unless p1
	   (mapc (lambda (x)
		   (when (string-match "R" (process-name x))
		     (push x lRProc)))
		 (process-list))
	   (set 'p1
		(car
		 (sort lRProc #'rp-processX-more-recent-p))))
	 (unless lRProc
	   (set 'p1 (rp-new-Rproc)))
	 p1))
	 
	   
(defun rp-new-Rproc () ""
       (interactive)
       (let (p1)
	 (set 'p1 (buffer-name (R)))
	 (set 'p1
	      (get-buffer-process p1))
	 p1))
	 
(defun rp-processX-more-recent-p (X Y)
  "
Returns t if the `process-buffer' associated with X is higher on the `buffer-list' than that for Y.
That is, X has more recently been active (display or selected)."
  (interactive)
  (<
   (cl-position (process-buffer X) (buffer-list))
   (cl-position (process-buffer Y) (buffer-list))))
       
(setq rp-input-ring (make-ring 0))

(defun rp-previous-input ()
  (interactive)
  (set 'r1 (car (ring-elements rp-input-ring)))
  (message
   (concat "rp-input-ring item: "
	   (prin1-to-string (cadr rp-input-ring))))
  (setcar rp-input-ring
	  (ring-plus1 (car rp-input-ring)  (cadr rp-input-ring)))
  (insert r1))   

(defun rp-send-line-or-region (&optional PROCESS) "h"
       (interactive)
       (unless PROCESS
	 (set 'PROCESS (rp-get-Rproc)))
       (let (toSend1 cb1)
	 (if (region-active-p)
	     (set 'toSend1
		  (buffer-substring-no-properties
		   (region-beginning) (region-end)))
	   (set 'toSend1
		(buffer-substring-no-properties
		 (line-beginning-position) (line-end-position))))
	 (set 'toSend1 (replace-regexp-in-string "^#*" "" toSend1))
	 (set 'toSend1 (replace-regexp-in-string "^'" "" toSend1))
	 (when (string-match "@include " toSend1)
	   (set 'toSend1 (replace-match "" nil nil toSend1))
	   (set 'toSend1 (replace-regexp-in-string "^ *" "" toSend1))
	   (set 'toSend1
		(concat "source('" toSend1 "')")))
	 (set 'cb1 (current-buffer))
	 (pop-to-buffer (process-buffer PROCESS))
	 (insert (concat toSend1 "\n"))
	 (ring-insert+extend rp-input-ring toSend1 t)
	 (set-marker (process-mark PROCESS) (point-max))
	 (if (featurep 'ess)
	     (ess-send-string PROCESS toSend1)
	   (process-send-string PROCESS toSend1))
	 (switch-to-buffer-other-window cb1)
	 (forward-line 1)))

(defun rp-pkg () "h"
       (interactive)
       (unless (eq (count-windows) 2)
	 (delete-other-windows)
	 (split-window-right))
       (let (cb1)
	 (set 'cb1 (current-buffer))
	 (when (buffer-file-name)
	   (save-buffer))
	 (set-window-buffer (window-at 1 1) cb1)
	 (switch-to-buffer-other-window "*R-package*")
	 (erase-buffer)
	 (switch-to-buffer-other-window cb1)
	 (rp-roxy)))

(defun rp-get-DESCRIPTION (&optional PACKAGE) "h"
       (interactive)
       (catch 'done
	 (let (d1)
	   (set 'd1
		(car
		 (directory-files default-directory t "^DESCRIPTION$")))
	   (unless d1
	     (set 'd1
		  (locate-dominating-file
		   (if (buffer-file-name)
		       (buffer-file-name)
		     default-directory)
		   "DESCRIPTION"))
	     (when (and PACKAGE (not d1))
	       (set 'd1
		    (concat default-directory PACKAGE "/")))
	     (when d1
	       (set 'd1
		    (car
		     (directory-files d1 t "^DESCRIPTION$")))))
	   (unless d1
	     (message "No DESCRIPTION file on this directory tree")
	     (throw 'done nil))
	   (set 'd1 (file-truename d1))
	   (message (prin1-to-string d1))
	   d1)))

(defun rp-get-package-name (DESCRIPTION) ""
       (interactive)
       (find-file DESCRIPTION)
       (search-forward "package: " nil t)
       (let (pn1)
	 (set 'pn1 (buffer-substring-no-properties
		    (point) (line-end-position)))
	 (replace-regexp-in-string " " "" pn1)
	 (kill-buffer (buffer-name))
	 pn1))

(defun rp-roxy (&optional DESCRIPTION PACKAGE) "h"
       (interactive)
       (catch 'done
	 (let (temp1 cb1 err1)
	   (unless DESCRIPTION
	     (set 'DESCRIPTION (rp-get-DESCRIPTION)))
	   (unless DESCRIPTION
	     (message "No DESCRIPTION file up this directory tree")
	     (throw 'done nil))
	   (unless PACKAGE
	     (set 'PACKAGE (rp-get-package-name DESCRIPTION)))
	   (set 'temp1
		(concat
		 ;; get name of parent directory of DESCRIPTION
		 (file-name-directory
		  (directory-file-name
		   (file-name-directory DESCRIPTION)))
		 "roxy.R"))
	   (with-temp-file temp1
	     (insert
	      (concat "
require('methods')
if (require('roxygen2')) roxygenize('" PACKAGE "')
"))
	     (write-file temp1))
	   (switch-to-buffer-other-window "*R-package*")
	   (goto-char (point-max))
	   (lexical-let (default-directory
			  ;; so these can be found by sentinel
			  (temp1 temp1)
			  (PACKAGE PACKAGE))
	     (set 'default-directory (file-name-directory temp1))
	     (set-process-sentinel
	      (start-process-shell-command
	       PACKAGE "*R-package*"
	       (concat "Rscript " temp1))
	      ;; PROCESS below = PACKAGE
	      (lambda (PROCESS EVENT)
		(message "rp-roxygen...done")
		(when
		    (not
		     (string-match-p "finished" EVENT))
		  (message "Roxygen not complete")
		  (when
		      (search-backward "roxygen block beginning " nil t)
		    (forward-word 3)
		    (set 'err1 (buffer-substring-no-properties
				(point) (line-end-position)))
		    (set 'fn1 (car (split-string err1 ":" t " ")))
		    (set 'l1 (cadr (split-string err1 ":" t " ")))
		    (switch-to-buffer-other-window
		     (find-file-noselect
		      (concat default-directory "/" PROCESS "/R/" fn1)))
		    (goto-char (point-min))
		    (forward-line (- 1 (string-to-number l1))))
		  (when (search-backward "Error in loadNamespace" nil t)
		    (find-file
		     (concat
		      default-directory
		      (process-name PROCESS) "/R/" 
		      (process-name PROCESS) "_package.R"))
		    (search-forward "@import" nil t)))
	     (when (string-match-p "finished" EVENT)
	       (delete-file temp1 t)
	       (message "Roxygen complete")
	       (rp-ex nil (process-name PROCESS)))))))))

(defun rp-ex (&optional DESCRIPTION PACKAGE) "h"
       (interactive)
       (catch 'done
	 (let (temp1 cb1 procRes1 rFile1 err1)
	   (when (not DESCRIPTION)
	     (set 'DESCRIPTION (rp-get-DESCRIPTION PACKAGE)))
	   (unless DESCRIPTION
	     (message "No DESCRIPTION file up this directory tree")
	     (throw 'done nil))
	   (unless PACKAGE
	     (set 'PACKAGE (rp-get-package-name DESCRIPTION)))
   	   (set 'temp1
		(concat
		 ;; get name of parent directory of d1
		 (file-name-directory
		  (directory-file-name
		   (file-name-directory DESCRIPTION)))
		 "ex.R"))
	   (with-temp-file temp1
	     (insert
	      (concat "
require('methods')
if (require('devtools')) run_examples('" PACKAGE "')
"))
	     (write-file temp1))
	   (pop-to-buffer "*R-package*")
	   (goto-char (point-max))
	   (lexical-let (default-directory
			  (temp1 temp1)
			  (PACKAGE PACKAGE))
	     (set 'default-directory (file-name-directory temp1))
	     (set-process-sentinel
	      (start-process-shell-command
	       PACKAGE "*R-package*"
	       (concat "Rscript " temp1))
	      (lambda (PROCESS EVENT)
		(message "rp-ex...done")
		(when
		    (not
		     (string-match-p "finished" EVENT))
		  (message "devtools::run_examples not complete")
		  (when (search-backward "Error " nil t)
		    (cond ((search-forward "block beginning " nil t)
			   (set 'err1 (buffer-substring-no-properties
				       (point) (line-end-position))))
			  ((search-backward "Running examples in " nil t)
			   (forward-word 3)
			   (set 'err1 (buffer-substring-no-properties
				       (point) (line-end-position)))))
		    (set 'rFile1
			 (replace-regexp-in-string "Rd" "R" err1))
		    (set 'rFile1
			 (replace-regexp-in-string " " "" rFile1))
		    (set 'rFile1
			 (car
			  (split-string rFile1 ":" t " ")))
		    (find-file
		      (concat
		       default-directory
		       (process-name PROCESS) "/R/" rFile1))
		     (goto-char (point-min))
		     (search-forward "@examples" nil t)))
		(when (string-match-p "finished" EVENT)
		  (message "devtools::run_examples complete")
		  (mapc #'delete-file
			(file-expand-wildcards 
			 (concat
			  (file-name-directory temp1) "Rplots*" )
			 t))
		  (delete-file temp1 t)
		  (rp-build nil (process-name PROCESS)))))))))


(defun rp-build (&optional DESCRIPTION PACKAGE) "h"
       (interactive)
       (catch 'done
	 (unless DESCRIPTION
	   (set 'DESCRIPTION (rp-get-DESCRIPTION PACKAGE)))
	 (unless DESCRIPTION
	   (message "No DESCRIPTION file up this directory tree")
	   (throw 'done nil))
	 (unless PACKAGE
	   (set 'PACKAGE (rp-get-package-name DESCRIPTION)))
	 (let (procRes1 targz1)
	   (pop-to-buffer "*R-package*")
	   (lexical-let (default-directory)
	     (set 'default-directory
		  ;; get name of parent directory of d1
		  (file-name-directory
		   (directory-file-name
		    (file-name-directory DESCRIPTION))))
	     (set-process-sentinel
	      (start-process-shell-command
	       PACKAGE "*R-package*"
	       (concat "R CMD build " PACKAGE))
	      (lambda (PROCESS EVENT)
		(message "rp-build...done")
		(when
		    (not
		     (string-match-p "finished" EVENT))
		  (message "R CMD build not complete"))
		(when (string-match-p "finished" EVENT)
		  (set 'targz1 (car
				(file-expand-wildcards
				 (concat
				  (process-name PROCESS) "*.tar.gz"))))
		  (rp-check targz1))))))))

(defun rp-check (TARGZ) "h"
       (interactive)
       (pop-to-buffer "*R-package*")
	 (lexical-let
	     ((TARGZ TARGZ))
	   (set-process-sentinel
	    (start-process-shell-command
	       "async-check" "*R-package*"
	       (concat "R CMD check " TARGZ))
	    (lambda (PROCESS EVENT)
	      (message "rp-check...done")
	      (when (not (string-match-p "finished" EVENT))
		(message "Error with check")
		(rp-log)
	      (when (string-match-p "finished" EVENT)
		(message "R CMD check complete")
		(rp-view TARGZ)))))))


(defun rp-log () "h"
       (interactive)
       (pop-to-buffer "*R-package*")
       (goto-char
	(point-max))
       (let (log1)
	 (set 'log1
	      (search-backward-regexp "for details.$" nil t))
	 (when log1
	   (set 'log1
		(buffer-substring-no-properties
		 (point) (line-end-position -1)))
	   (set 'log1
		(replace-regexp-in-string "[ ‘’\n]" "" log1))
	   (find-file log1)
	   (goto-char
	    (point-max))
	   (cond ((search-backward "")))
	 (if log1 t nil))))

(defun rp-view (PACKAGE) "h"
       (interactive)
       (let (p1 m1)
	 (set 'p1 (replace-regexp-in-string "_.*" "" PACKAGE))
	 (set 'm1 (concat p1 "-manual.pdf"))
	 (pop-to-buffer "*R-package*")))
	 ;(find-alternate-file (concat "./" p1 ".Rcheck/" m1))))
       

;; from http://www.emacswiki.org/emacs/NavigatingParentheses
(defun rp-string-forward (&optional limit)
  (if (eq (char-after) ?\")
      (catch 'done
	(forward-char 1)
	(while t
	  (skip-chars-forward "^\\\\\"" limit)
	  (cond ((eq (point) limit)
		 (throw 'done nil))
		((eq (char-after) ?\")
		 (forward-char 1)
		 (throw 'done nil))
		(t
		 (forward-char 1)
		 (if (eq (point) limit)
		     (throw 'done nil)
		   (forward-char 1))))))))
   
 (defun rp-string-backward (&optional limit)
     (if (eq (char-before) ?\")
         (catch 'done
           (forward-char -1)
           (while t
             (skip-chars-backward "^\"" limit)
             (if (eq (point) limit)
                 (throw 'done nil) )
             (forward-char -1)
             (if (eq (point) limit)
                 (throw 'done nil) )
             (if (not (eq (char-before) ?\\))
                 (throw 'done nil) ) ) ) ) )
   
(defun forward-pexp (&optional arg)
     (interactive "p")
     (or arg (setq arg 1))
     (let (open close next notstrc notstro notstre depth pair)
       (catch 'done
         (cond ((> arg 0)
                (skip-chars-forward " \t\n")
                (if (not (memq (char-after) '(?\( ?\[ ?\{ ?\<)))
                   (goto-char (or (scan-sexps (point) arg) (buffer-end arg)))
                  (skip-chars-forward "^([{<\"")
                  (while (eq (char-after) ?\")
                   (rp-string-forward)
                   (skip-chars-forward "^([{<\"") )
                  (setq open (char-after))
                  (if (setq close (cadr (assq open '( (?\( ?\))
                                                      (?\[ ?\])
                                                      (?\{ ?\})
                                                      (?\< ?\>) ) ) ) )
                      (progn
                        (setq notstro (string ?^ open ?\")
                              notstre (string ?^ open close ?\") )
                        (while (and (> arg 0) (not (eobp)))
                          (skip-chars-forward notstro)
                          (while (eq (char-after) ?\")
                           (if (eq (char-before) ?\\)
                                (forward-char 1)
                              (rp-string-forward) )
                           (skip-chars-forward notstro) )
                          (forward-char 1)
                          (setq depth 1)
                          (while (and (> depth 0) (not (eobp)))
                           (skip-chars-forward notstre)
                           (while (eq (char-after) ?\")
                              (if (eq (char-before) ?\\)
                                  (forward-char 1)
                                (rp-string-forward) )
                              (skip-chars-forward notstre) )
                           (setq next (char-after))
                           (cond ((eq next open)
                                   (setq depth (1+ depth)) )
                                  ((eq next close)
                                   (setq depth (1- depth)) )
                                  (t
                                   (throw 'done nil) ) )
                           (forward-char 1) )
                          (setq arg (1- arg) ) ) ) ) ) )
               ((< arg 0)
                (skip-chars-backward " \t\t")
                (if (not (memq (char-before) '(?\) ?\] ?\} ?\>)))
                   (progn
                      (goto-char (or (scan-sexps (point) arg) (buffer-end arg)))
                      (backward-prefix-chars) )
                  (skip-chars-backward "^)]}>\"")
                  (while (eq (char-before) ?\")
                   (rp-string-backward)
                   (skip-chars-backward "^)]}>\"") )
                  (setq close (char-before))
                  (if (setq open (cadr (assq close '( (?\) ?\()
                                                      (?\] ?\[)
                                                      (?\} ?\{)
                                                      (?\> ?\<) ) ) ) )
                      (progn
                        (setq notstrc (string ?^ close ?\")
                              notstre (string ?^ close open ?\") )
                        (while (and (< arg 0) (not (bobp)))
                          (skip-chars-backward notstrc)
                          (while (eq (char-before) ?\")
                           (if (eq (char-before (1- (point))) ?\\)
                                (forward-char -1)
                              (rp-string-backward) )
                           (skip-chars-backward notstrc) )
                          (forward-char -1)
                          (setq depth 1)
                          (while (and (> depth 0) (not (bobp)))
                           (skip-chars-backward notstre)
                           (while (eq (char-before) ?\")
                              (if (eq (char-before (1- (point))) ?\\)
                                  (forward-char -1)
                                (rp-string-backward) )
                              (skip-chars-backward notstre) )
                           (setq next (char-before))
                           (cond ((eq next close)
                                   (setq depth (1+ depth)) )
                                  ((eq next open)
                                   (setq depth (1- depth)) )
                                  (t
                                   (throw 'done nil) ) )
                           (forward-char -1) )
                          (setq arg (1+ arg)) ) ) ) ) ) ) ) ))
   
(setq forward-sexp-function #'forward-pexp)

(defun rp-eval-function-args (&optional MATCHARG) "help"
 (interactive
  (list
   (y-or-n-p-with-timeout "match.arg()-like behavior? " 2 t)))
 (let (cb1 toSend1 p1 p2 s1 pr1)
   (set 'cb1 (current-buffer))
   (backward-paragraph)
    (when (search-forward "function" nil t)
      (set 'p1 (point))
      (forward-sexp)
      (set 'p2 (point))
      (set 's1 (buffer-substring-no-properties p1 p2))
      (with-temp-buffer
	(pop-to-buffer (buffer-name))
	(insert s1)
	(whitespace-cleanup)
	(goto-char (point-min))
	(delete-char 1)
	(goto-char (point-max))
	(delete-char -1)
	(goto-char (point-min))
	(while (search-forward "...," nil t)
	  (when (equal
		 (car
		  (parse-partial-sexp (point-min) (point))) 0)
	    (replace-match "" nil t)))
	(goto-char (point-min))
	(while (search-forward "..." nil t)
	  (when (equal
		 (car
		  (parse-partial-sexp (point-min) (point))) 0)
	    (replace-match "" nil t)))
	(goto-char (point-min))
	(while (re-search-forward "," nil t)
	  (when
	      (equal
	       (car
		(parse-partial-sexp
		 (point-min) (point))) 0)
	    (replace-match "" nil t)))
	(when MATCHARG
	  (goto-char (point-min))
	  (while (re-search-forward "c(" nil t)
	    (search-forward ",")
	    (replace-match ")")
	    (zap-to-char 1 (string-to-char ")"))))
	(set 'pr1 (rp-get-Rproc))
	(display-buffer-use-some-window (process-buffer pr1) nil)
	(set-marker
	 (process-mark pr1) (point-max) (process-buffer pr1))
	(if (featurep 'ess)
	    (ess-send-region
	     pr1 (point-min) (point-max) t)
	  (process-send-region
	   pr1 (point-min) (point-max))))
      (goto-char (point-max))
      (process-send-string pr1 "\n")
      (switch-to-buffer-other-window cb1)
      (backward-paragraph)
      (when (search-forward "function" nil t)
	(forward-pexp))
      (forward-line 1))))


(provide 'rp)

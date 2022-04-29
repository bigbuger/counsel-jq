;;; counsel-jq-ex.el --- Live preview of "jq" queries using counsel -*- lexical-binding: t -*-
;;; Version: 1.1.0
;;; Author: Alain M. Lafon <alain@200ok.ch)
;;; Package-Requires: ((swiper "0.12.0") (ivy "0.12.0") (emacs "24.1"))
;;; Keywords: convenience, data, matching
;;; URL: https://github.com/200ok-ch/counsel-jq
;;; Commentary:
;;;   Needs the "jq" binary installed.
;;; Code:

(require 'swiper)

(defcustom counsel-jq-json-buffer-mode 'js-mode
  "Major mode for the resulting `counsel-jq-buffer' buffer."
  :type '(function)
  :require 'counsel-jq-ex
  :group 'counsel-jq-ex)

(defcustom counsel-jq-command "jq"
  "Command for `counsel-jq'.")

(defcustom counsel-jq-buffer "*jq-json*"
  "Buffer for the `counsel-jq' query results.")

(defun counsel-call-jq (&optional query args output-buffer)
  "Call 'jq' use OUTPUT-BUFFER as output (default is 'standard-output'), with the QUERY and ARGS."
  (call-process-region
   (point-min)
   (point-max)
   counsel-jq-command
   nil
   (or output-buffer standard-output)
   nil
   (or args  "-M")
   (or query ".")))
    


(defun counsel-jq-json (&optional query)
  "Call 'jq' with the QUERY with a default of '.'."
  (with-current-buffer
      ;; The user entered the `counsel-jq` query in the minibuffer.
      ;; This expression uses the most recent buffer ivy-read was
      ;; invoked from.
      (ivy-state-buffer ivy-last)
    (counsel-call-jq query nil counsel-jq-buffer)))

(defun counsel-jq-query-function (input)
  "Wrapper function passing INPUT over to `counsel-jq-json'."
  (when (get-buffer counsel-jq-buffer)
      (with-current-buffer counsel-jq-buffer
        (funcall counsel-jq-json-buffer-mode)
        (erase-buffer)))
  (counsel-jq-json input))

(defcustom counsel-jq-path-query
  "[ path(..) | map(select(type == \"string\") // \"[]\") | join(\".\") ] | sort | unique | .[] | split(\".[]\") | join(\"[]\") | \".\" + ."
  "Use jq to get all json path.")

(defun counsel-jq-path (buffer)
  "Get all json path in BUFFER."
  (with-current-buffer buffer
    (split-string
     (with-output-to-string
       (counsel-call-jq counsel-jq-path-query "-r"))
     "\n")))


(defvar counsel-jq-ex-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<tab>") 'ivy-partial)
    map))

;;;###autoload
(defun counsel-jq-ex ()
  "Counsel interface for dynamically querying jq.
Whenever you're happy with the query, hit RET and the results
will be displayed to you in the buffer in `counsel-jq-buffer'."
  (interactive)
  (let ((canditdates (counsel-jq-path (current-buffer))))
    (ivy-read "jq query: " #'(lambda (input)
			       (counsel-jq-query-function input)
			       (display-buffer counsel-jq-buffer)
			       canditdates)
              :action #'(1
			 ("s" (lambda (_)
				(display-buffer counsel-jq-buffer))
                          "show"))
              :initial-input "."
              :dynamic-collection t
	      :keymap counsel-jq-ex-map
              :caller 'counsel-jq-ex)))
  

(provide 'counsel-jq-ex)

;;; counsel-jq-ex.el ends here

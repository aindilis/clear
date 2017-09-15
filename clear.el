;;; clear.el --- Emacs helpers for CLEAR

;; Copyright (C) 2005  Free Software Foundation, Inc.

;; Author: Jason Sayne <jasayne@frdcsa>
;; Keywords: tools

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; CLEAR helpers for Emacs

;;; Code:

;; (add-hook 'clear-mode-hook
;;  '(lambda ()
;;    (define-key clear-mode-map "\C-c\C-mc"
;;     'clear-queue-all-links)
;;    'w3m-view-this-url)
;;  (define-key clear-mode-map "\C-c\C-mb"
;;   'clear-queue-current-buffer-referent))

(add-hook 'w3m-mode-hook (lambda () (local-unset-key "\C-c\C-m")))

(global-set-key "\C-c\C-ma" 'clear-queue-all-links)
(global-set-key "\C-c\C-mb" 'clear-queue-current-buffer-referent)
(global-set-key "\C-c\C-ms" 'clear-read-current-buffer-referent-with-spread0r)
(global-set-key "\C-c\C-ml" 'clear-queue-link)
(global-set-key "\C-c\C-mf" 'clear-queue-filename)
(global-set-key "\C-c\C-mr" 'clear-queue-current-region)
(global-set-key "\C-c\C-mR" 'clear-queue-current-rectangular-region)
(global-set-key "\C-c\C-mt" 'clear-queue-tos)
(global-set-key "\C-c\C-mS" 'clear-send)
(global-set-key "\C-c\C-mp" 'clear-pause)

(defun clear-send (&optional command)
 "Send a quick 'yes' to clear"
 (interactive)
 (uea-send-contents (concat "CLEAR, " (or command (read-from-minibuffer "Send CLEAR what?: ")))))

(defun clear-pause ()
 ""
 (interactive)
 ;; (kmax-not-yet-implemented)
 (clear-send "p"))

(defun clear-queue-current-buffer-referent ()
 "Queue the object that the buffer points to, for instance a file,
url, man or info page, etc"
 (interactive)
 (let
  ((file
    (cond
     ((derived-mode-p 'doc-view-mode)
      doc-view--buffer-file-name)
     ((buffer-file-name (current-buffer))
      (file-chase-links (buffer-file-name (current-buffer))))
     ((eq major-mode 'w3m-mode)
      (w3m-print-current-url))
     (t
      (save-excursion
       (mark-whole-buffer)
       (kill-ring-save (point) (mark))
       (generate-new-buffer "cleartmp")
       (set-buffer (get-buffer "cleartmp"))
       (yank)
       (shell-command "rm /tmp/clear.txt /tmp/clear.txt.voy")
       (write-file "/tmp/clear.txt")
       (kill-buffer (get-buffer "cleartmp"))
       "/tmp/clear.txt")))))
  (if file
   (progn
    ;; have to fix this to list the newest agent
    (if (not uea-connected)
     (uea-connect-as-nth-emacs-client "2"))
    (uea-send-contents (concat "CLEAR, queue " file))))))

(defun clear-read-current-buffer-referent-with-spread0r ()
 "Queue the object that the buffer points to, for instance a file,
url, man or info page, etc"
 (interactive)
 (let
  ((file
    (cond
     ((buffer-file-name (current-buffer))
      (buffer-file-name (current-buffer)))
     ((eq major-mode 'w3m-mode)
      (w3m-print-current-url))
     (t
      (save-excursion
       (mark-whole-buffer)
       (kill-ring-save (point) (mark))
       (generate-new-buffer "cleartmp")
       (set-buffer (get-buffer "cleartmp"))
       (yank)
       (shell-command "rm /tmp/clear.txt /tmp/clear.txt.voy")
       (write-file "/tmp/clear.txt")
       (kill-buffer (get-buffer "cleartmp"))
       "/tmp/clear.txt")))))
  (if file
   (run-in-shell (concat "cd /var/lib/myfrdcsa/repositories/external/git/spread0r && ./spread0r.pl -w 500 " (shell-quote-argument file))))))

(defun clear-queue-tos ()
 "Queue the buffer's current region"
 (interactive)
 (let
  ((file
    (progn
     (generate-new-buffer "cleartmp")
     (set-buffer (get-buffer "cleartmp"))
     (freekbs2-insert-top-of-stack)
     (shell-command "rm /tmp/clear.txt /tmp/clear.txt.voy")
     (write-file "/tmp/clear.txt")
     (kill-buffer (get-buffer "cleartmp"))
     "/tmp/clear.txt")))
  (if file
   (uea-send-contents (concat "CLEAR, queue " file)))))

;; (uea-send-contents (concat "CLEAR, queue " (w3m-print-current-url)))

(defun clear-queue-current-region (start end)
 "Queue the buffer's current region"
 (interactive "r")
 (let
  ((file
    (progn
     (kill-ring-save start end)
     (generate-new-buffer "cleartmp")
     (set-buffer (get-buffer "cleartmp"))
     (yank)
     (shell-command "rm /tmp/clear.txt /tmp/clear.txt.voy")
     (write-file "/tmp/clear.txt")
     (kill-buffer (get-buffer "cleartmp"))
     "/tmp/clear.txt")))
  (if file
   (uea-send-contents (concat "CLEAR, queue " file)))))

(defun clear-queue-current-rectangular-region (start end)
 "Queue the buffer's current region"
 (interactive "r")
 (let
  ((file
    (save-excursion
     (kill-rectangle start end)
     (kill-ring-save start end)
     (generate-new-buffer "cleartmp")
     (set-buffer (get-buffer "cleartmp"))
     (yank-rectangle)
     (shell-command "rm /tmp/clear.txt /tmp/clear.txt.voy")
     (write-file "/tmp/clear.txt")
     (kill-buffer (get-buffer "cleartmp"))
     "/tmp/clear.txt")))
  (if file
   (uea-send-contents (concat "CLEAR, queue " file)))))

(defun clear-show-current-buffer-referent-old ()
 "Queue the object that the buffer points to, for instance a file,
url, man or info page, etc"
 (interactive)
 (message
  (or (buffer-file-name (current-buffer))
   (when (and (boundp 'list-buffers-directory)
	  list-buffers-directory)
    list-buffers-directory))))

(defun clear-show-current-buffer-referent ()
 "Queue the object that the buffer points to, for instance a file,
url, man or info page, etc"
 (interactive)
 (message
  (or (buffer-file-name (current-buffer))
   (progn (write-file "/tmp/clear.txt")
    "/tmp/clear.txt"))))

(defun clear-queue-link ()
 "Send a message to clear to queue all links"
 (interactive)
 (uea-send-contents (concat "CLEAR, queue " (w3m-print-this-url))))

(defun clear-queue-filename (&optional filename)
 "Send a message to clear to queue all links"
 (interactive)
 (uea-send-contents
  (concat "queue " 
   (if filename
    filename
    (thing-at-point 'filename))) "CLEAR"))

(defun clear-queue-all-links (start end)
 "Send a message to clear to queue all links"
 (interactive "r")
 (w3m-map-command-all-links start end
  '(lambda (arg) 
    (progn
     (uea-send-contents (concat "CLEAR, queue " arg))
     ;; should not be necessary (sit-for 1.0)
     ))))

(defun clear-test-send ()
 ""
 (interactive)
 (uea-send-contents (concat "CLEAR, queue http://frdcsa.org")))

(defun w3m-map-command-all-links (start end command &optional)
 "Queue to SYSTEM all http links between START and END."
 (when (w3m-region-active-p)
  (w3m-deactivate-region))
 (let (
       (buffer (current-buffer))
       (prev start)
       (url (w3m-url-valid (w3m-anchor start)))
       urls)
  (when url
   (setq urls (list url)))
  (save-excursion
   (goto-char start)
   (while (progn
	   (w3m-next-anchor)
	   (and (> (point) prev)
	    (< (point) end)))
    (setq prev (point))
    (when (and (setq url (w3m-url-valid (w3m-anchor)))
	   (string-match "\\`https?:" url))
     (push url urls))))
  (setq urls (reverse urls))
  (while urls
   (setq url (car urls)
    urls (cdr urls))
   (set-buffer buffer)
   (funcall command url))))

(defun clear-reread ()
 ""
 )

(provide 'clear)
;;; clear.el ends here

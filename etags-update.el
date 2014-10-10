;; etags-update-mode
;;
;; Minor mode to update TAGS file on save. TAGS file used is head of
;; tags-table-list or otherwise tags-file-name.
;;
;; Copyright (C) 2014 Maksim Grinman
;; Author: Maksim Grinman <maxchgr@gmail.com>
;; Keywords: etags
;; 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

(defun etu/get-tags-table ()
  (save-current-buffer
    (tags-table-check-computed-list)
    (or
     ;; Check if a tags table has tags for our file
     (and buffer-file-name
          (or
           ;; First check only tables already in buffers.
           (tags-table-including buffer-file-name t)
           ;; Since that didn't find any, now do the
           ;; expensive version: reading new files.
           (tags-table-including buffer-file-name nil)))
     ;; Second, try a user-specified function
     (and default-tags-table-function
          (funcall default-tags-table-function))
     ;; Finally, prompt the user for a file name.
     (expand-file-name
      (read-file-name "Choose tags table to save to: "
                      default-directory
                      tags-file-name
                      t)))))

(defun etu/etags-update ()
  "Copy tags contents to tmp buffer, remove section(s) for this
buffer from TAGS file, run etags --append for buffer's file, and
if successful overwrite TAGS with the result. The TAGS file
chosen is the car of tags-table-list, or tags-file-name if
tags-table-file is empty."
  (let* (
         (tagspath (etu/get-tags-table))
         (tagstmppath (concat tagspath "TMP"))
         (thisbuf buffer-file-name)
         ;; buffer name relative to TAGS file dir
         (file-section (replace-regexp-in-string
                        (file-name-directory tagspath) ""
                        thisbuf)))
    (unless (file-exists-p tagspath) 
      (error "%s doesn't exist." tagspath))
    (with-temp-file tagspath
      (insert-file-contents tagspath)
      (widen)
      (goto-char (point-min))
      (etu/etags-delete-file-section file-section))
    ;; (write-region (point-min) (point-max) tagstmppath)
    (let ((cmd (format "cd %s; ctags -e -o %s -a %s"
                       (file-name-directory tagspath)
                       tagspath
                       file-section
                       )))
      (start-process-shell-command "etags-append" "*etags-update*" cmd)
      (set-process-sentinel (get-process "etags-append")
                            (lambda (process status)
                              (if (string= status "finished\n")
                                  (message "Updated TAGS file %s..." (etu/get-tags-table))
                                (error "Updating TAGS file failed. Event was %s. See buffer %s." event "*etags-update*"))))
      )))

(defun etu/etags-delete-file-section (filename)
  "Removes the section for filename in the active buffer, which
should be a copy of the TAGS file contents. Filename should be
relative to the TAGS directory path. Return true if found and
deleted the section, false if not."
  (let ((found nil))
    (while (re-search-forward "\f" nil t)
      (if (looking-at-p (concat "\n" filename ",[0-9]+$"))
          (let ((del-start (match-beginning 0))
                (del-end (if (re-search-forward "\f" nil t)
                             (progn (setq found t)
                                    (match-beginning 0))
                           (point-max))))
            (delete-region del-start del-end))))
    found))

;;;###autoload
(define-minor-mode etags-update-mode
  "Update etags TAGS file on save. TAGS file should already
  exist. You are responsible for making sure the TAGS table is
  the correct one."
  :lighter " etu"
  (if etags-update-mode
      (add-hook 'after-save-hook 'etu/etags-update nil 'make-it-local)
    (remove-hook 'after-save-hook 'etu/etags-update 'make-it-local)))

(setq tags-revert-without-query t)
(add-hook 'nxml-mode-hook 'etags-update-mode)

(provide 'etags-update)

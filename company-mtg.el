;;; company-mtg.el --- Company backend for MTG cards  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Mathieu Marques

;; Author: Mathieu Marques <mathieumarques78@gmail.com>
;; Created: June 10, 2017
;; Homepage: https://github.com/angrybacon/company-mtg
;; Keywords: abbrev, convenience, games
;; Package-Requires: ((company "0.9"))
;; Version: 0.1.0

;; This program is free software. You can redistribute it and/or modify it under
;; the terms of the Do What The Fuck You Want To Public License, version 2 as
;; published by Sam Hocevar.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.
;;
;; You should have received a copy of the Do What The Fuck You Want To Public
;; License along with this program. If not, see http://www.wtfpl.net/.

;;; Commentary:

;; This package provides a backend for Company.
;; Get a JSON dump of all the cards at http://www.mtgjson.com/.

;;; Code:


(require 'cl-lib)
(require 'company)
(require 'json)


;;;; Variables


(defgroup company-mtg nil
  "Company backend for `mtg'."
  :group 'company
  :prefix "company-mtg-")

(defcustom company-mtg-annotation-function 'company-mtg-annotation-mana
  "The function to use to annotate candidates."
  :group 'company-mtg
  :type 'function)

(defcustom company-mtg-data-file "AllCards.json"
  "The file to read data from. Should be a JSON file."
  :group 'company-mtg
  :type 'string)

(defcustom company-mtg-match-function 'string-prefix-p
  "The matching function to use when finding candidates.
You can set this variable to `company-mtg-match-fuzzy' or define your own function."
  :group 'company-mtg
  :type 'function)


;;;; Functions

;; (require 'lui-format)
(defun company-mtg-annotation-mana (candidate)
  (let* ((mana-cost (get-text-property 0 :mana-cost candidate))
         (result (when mana-cost (format " %s" mana-cost))))
    result))

(defun company-mtg-match-fuzzy (prefix string &optional ignore-case)
  (cl-subsetp (string-to-list prefix) (string-to-list string)))

(defvar company-mtg-candidates nil "Store candidates after fetching cards.")

;;;###autoload
(defun company-mtg-load-candidates ()
  "Read data from JSON, format it to be company-compatible and store it inside
`company-mtg-candidates'.
See https://mtgjson.com/."
  (interactive)
  (setq company-mtg-candidates nil)
  (dolist (card (json-read-file company-mtg-data-file))
    (let ((name (symbol-name (car card)))
          (data (cdr card)))
      (add-text-properties 0 1
                           `(:layout
                             ,(cdr (assoc 'layout data))
                             :name ,(cdr (assoc 'name data))
                             :mana-cost ,(cdr (assoc 'manaCost data))
                             :cmc ,(cdr (assoc 'cmc data))
                             :colors ,(cdr (assoc 'colors data))
                             :type ,(cdr (assoc 'type data))
                             :types ,(cdr (assoc 'types data))
                             :subtypes ,(cdr (assoc 'subtypes data))
                             :text ,(cdr (assoc 'text data))
                             :power ,(cdr (assoc 'power data))
                             :toughness ,(cdr (assoc 'toughness data))
                             :image-name ,(cdr (assoc 'imageName data))
                             :color-identity ,(cdr (assoc 'layout data)))
                           name)
      (push name company-mtg-candidates)))
  (setq company-mtg-candidates (nreverse company-mtg-candidates))
  (message "Company-mtg: loaded %s" company-mtg-data-file))

;;;###autoload
(defun company-mtg (command &optional argument &rest ignored)
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-mtg))
    (prefix (and (eq major-mode 'mtg-deck-mode)
                 (company-grab-line "^\\([1-9] \\)?\\(.+\\)" 2)))
    (candidates
     (cl-remove-if-not
      (lambda (c) (funcall company-mtg-match-function argument c t))
      company-mtg-candidates))
    (annotation (funcall company-mtg-annotation-function argument))))

;; (setq company-mtg-match-function 'string-prefix-p)
;; (setq company-mtg-match-function 'company-mtg-match-fuzzy)
;; (add-to-list 'company-backends 'company-mtg)
;; (company-mtg-load-candidates)

(provide 'company-mtg)
;;; company-mtg.el ends here

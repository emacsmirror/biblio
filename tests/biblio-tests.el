;;; biblio-tests.el --- Tests for the biblio package -*- lexical-binding: t -*-

;; Copyright (C) 2016  Clément Pit-Claudel

;; Author: Clément Pit-Claudel
;; Version: 0.1
;; Package-Requires: ((biblio-core "0.0") (biblio-doi "0.0"))
;; Keywords: bib, tex, convenience, hypermedia
;; URL: http://github.com/cpitclaudel/biblio.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;

;;; Code:

(when (require 'undercover nil t)
  (undercover "*.el"))

(require 'biblio)
(require 'buttercup)

(defconst stallman-bibtex "@ARTIcle{Stallman_1981, title={EMACS the extensible,
customizable self-documenting display editor}, volume={2},
ISSN=\"0737-819X\",
url={http://dx.doi.org/10.1145/1159890.806466},
DOI={10.1145/1159890.806466}, number={1-2}, journal={ACM SIGOA
Newsletter}, publisher={Association for Computing
Machinery (ACM)}, author={Stallman, Richard M.}, year={1981},
month={Apr}, pages={147–156}}")

(defconst stallman-bibtex-clean "
  author       = {Stallman, Richard M.},
  title	       = {EMACS the extensible, customizable self-documenting
                  display editor},
  year	       = 1981,
  volume       = 2,
  number       = {1-2},
  month	       = {Apr},
  pages	       = {147–156},
  issn	       = {0737-819X},
  doi	       = {10.1145/1159890.806466},
  url	       = {http://dx.doi.org/10.1145/1159890.806466},
  journal      = {ACM SIGOA Newsletter},
  publisher    = {Association for Computing Machinery (ACM)}
}")

(defconst sample-items
  '(((backend . biblio-dblp-backend)
     (title . "Who builds a house without drawing blueprints?")
     (authors "Leslie Lamport") (container . "Commun. ACM") (type . "Journal Articles")
     (url . "http://dblp.org/rec/journals/cacm/Lamport15"))
    ((backend . biblio-dblp-backend)
     (title . "Turing lecture: The computer science of concurrency: the early years.")
     (authors "Leslie Lamport") (container . "Commun. ACM") (type . "Journal Articles")
     (url . "http://dblp.org/rec/journals/cacm/Lamport15a"))
    ((backend . biblio-dblp-backend)
     (title . "An incomplete history of concurrency chapter 1. 1965-1977.")
     (authors "Leslie Lamport") (container . "PODC") (type . "Conference and Workshop Papers")
     (url . "http://dblp.org/rec/conf/podc/Lamport13"))
    ((backend . biblio-dblp-backend)
     (title . "Euclid Writes an Algorithm: A Fairytale.")
     (authors "Leslie Lamport") (container . "Int. J. Software and Informatics") (type . "Journal Articles")
     (url . "http://dblp.org/rec/journals/ijsi/Lamport11"))))

(describe "Unit tests:"
  (describe "In biblio's core,"
    (describe "in the compatibility section,"
      (let ((alist '((a . 1) (b . 2) (c . 3) (c . 4)))
            (plist '(a  1 b 2 c 3 c 4)))
        (describe "-alist-get"
          (it "can read values from alists"
            (expect (biblio-alist-get 'a alist) :to-equal 1)
            (expect (biblio-alist-get 'b alist) :to-equal 2)
            (expect (biblio-alist-get 'c alist) :to-equal 3)))
        (describe "-plist-to-alist"
          (it "can convert plists"
            (expect (biblio--plist-to-alist plist) :to-equal alist)))))
    (describe "in the utilities section,"
      (describe "-format-bibtex"
        (xit "does not throw on invalid entries"
          (expect (biblio-format-bibtex "@!!") :to-equal "@!!")
          (expect (biblio-format-bibtex "@article{KEY,}") :to-equal "@article{}"))
        (it "formats a typical example properly"
          (expect (biblio-format-bibtex stallman-bibtex)
                  :to-equal (concat "@Article{Stallman_1981," stallman-bibtex-clean)))
        (it "properly creates missing keys"
          (expect (biblio-format-bibtex stallman-bibtex t)
                  :to-equal (concat "@Article{stallman81:emacs," stallman-bibtex-clean))))
      (describe "-response-as-utf8"
        (it "decodes Unicode characters properly"
          (let ((unicode-str "É Ç € ← 有"))
            (with-temp-buffer
              (insert unicode-str)
              (goto-char (point-min))
              (set-buffer-multibyte nil)
              (expect (biblio-response-as-utf-8) :to-equal unicode-str)))))
      (describe "-check-for-retrieval-error"
        (let ((http-error '(error http 406))
              (timeout-error '(error url-queue-timeout "Queue timeout exceeded")))
          (it "supports empty lists"
            (expect (biblio-check-for-retrieval-error nil) :to-equal nil))
          (it "supports whitelists"
            (expect (biblio-check-for-retrieval-error `(:error ,http-error) '(http . 406))
                    :to-equal `((http . 406))))
          (it "handles timeouts specially"
            (let ((timeout-error-plist `(:error ,timeout-error)))
              (expect (biblio-check-for-retrieval-error timeout-error-plist)
                      :to-equal '(error . timeout))))
          (it "returns the first error"
            (expect (biblio-check-for-retrieval-error `(:error ,http-error :error ,timeout-error))
                    :to-equal `(error . (http . 406)))
            (expect (biblio-check-for-retrieval-error `(:error ,timeout-error :error ,http-error))
                    :to-equal `(error . timeout)))))
      (describe "-cleanup-doi"
        (it "Handles prefixes properly"
          (expect (biblio-cleanup-doi "http://dx.doi.org/10.5281/zenodo.44331")
                  :to-equal "10.5281/zenodo.44331")
          (expect (biblio-cleanup-doi "http://doi.org/10.5281/zenodo.44331")
                  :to-equal "10.5281/zenodo.44331"))
        (it "trims spaces"
          (expect (biblio-cleanup-doi "   10.5281/zenodo.44331 \n\t\r ")
                  :to-equal "10.5281/zenodo.44331"))
        (it "doesn't change clean DOIs"
          (expect (biblio-cleanup-doi "10.5281/zenodo.44331")
                  :to-equal "10.5281/zenodo.44331")))
      (describe "-join"
        (it "removes empty entries before joining"
          (expect (biblio-join ", " "a" nil "b" nil "c" '[]) :to-equal "a, b, c")
          (expect (biblio-join-1 ", " '("a" nil "b" nil "c" [])) :to-equal "a, b, c"))))
    (describe "in the major mode help section"
      :var (temp-buf doc-buf)
      (before-each
        (with-current-buffer (setq temp-buf (get-buffer-create " *temp*"))
          (shut-up
            (biblio-selection-mode)
            (setq doc-buf (biblio--help-with-major-mode)))))
      (after-each
        (kill-buffer doc-buf)
        (kill-buffer temp-buf))
      (describe "--help-with-major-mode"
        (it "produces a live buffer"
          (expect (buffer-live-p doc-buf) :to-be-truthy))
        (it "shows bindings in order"
          (expect (with-current-buffer doc-buf
                    (and (search-forward "<up>" nil t)
                         (search-forward "<down>" nil t)))
                  :to-be-truthy))))
    (describe "in the interaction section,"
      :var (source-buffer selection-buffer)
      (before-all
        (shut-up
          (setq source-buffer (get-buffer-create " *selection*"))
          (setq selection-buffer (biblio-insert-results source-buffer "B" sample-items))))
      (after-all
        (kill-buffer source-buffer)
        (kill-buffer selection-buffer))
      (describe "a motion command"
        (it "can go down"
          (with-current-buffer selection-buffer
            (expect (point) :not :to-equal (biblio--selection-next))
            (expect (point) :not :to-equal (biblio--selection-next))
            (expect (biblio-alist-get 'title (biblio--selection-metadata-at-point))
                    :to-match "^An incomplete history ")))
        (it "cannot go beyond the end"
          (with-current-buffer selection-buffer
            (dotimes (_ 50)
              (biblio--selection-next))
            (expect (point) :to-equal (biblio--selection-next))))
        (it "can go up"
          (with-current-buffer selection-buffer
            (goto-char (point-max))
            (expect (point) :not :to-equal (biblio--selection-previous))
            (expect (point) :not :to-equal (biblio--selection-previous))
            (expect (point) :not :to-equal (biblio--selection-previous))
            (expect (point) :not :to-equal (point-max))
            (expect (biblio-alist-get 'title (biblio--selection-metadata-at-point))
                    :to-match "^Turing lecture")))
        (it "cannot go beyond the beginning"
          (with-current-buffer selection-buffer
            (goto-char (point-max))
            (dotimes (_ 50)
              (biblio--selection-previous))
            (expect (point) :to-equal 3)
            (expect (point) :to-equal (biblio--selection-previous)))))
      (describe "-get-url"
        (it "works on each item"
          (with-current-buffer selection-buffer
            (while (not (eq (point) (biblio--selection-next)))
              (expect (biblio-get-url (biblio--selection-metadata-at-point))
                      :to-match "^http://")))))))

  (describe "In the arXiv module"
    (describe "biblio-arxiv--extract-year"
      (it "parses correct dates"
        (expect (biblio-arxiv--extract-year "2003-07-07T13:46:39")
                :to-equal "2003")
        (expect (biblio-arxiv--extract-year "2003-07-07T13:46:39-04:00")
                :to-equal "2003")
        (expect (biblio-arxiv--extract-year "1995-06-02T01:02:52+02:00")
                :to-equal "1995"))
      (it "rejects invalid dates"
        (expect (biblio-arxiv--extract-year "Mon Mar 21 19:24:32 EDT 2016")
                :to-equal nil)))))

(provide 'biblio-tests)
;;; biblio-tests.el ends here

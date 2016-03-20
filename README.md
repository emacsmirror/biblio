# `biblio.el`: An Emacs package for browsing and fetching references

`biblio.el` makes it easy to browse and gather bibliographic references and
publications from various sources, by keywords or by DOI.  References are
automatically fetched from well-curated sources, and formatted as BibTeX.

## Supported sources:

* `dx.doi.org` to retrieve BibTeX records from DOIs
* `CrossCite` to format BibTeX records if unavailable from the DOI owner
* `CrossRef` for general searches
* `DBLP` specialized in computer science
* `Dissemin` to gather information about a particular publication, such as its open acces status

## Usage

Each source can be accessed independently:

* `M-x crossref-lookup` to query CrossRef
* `M-x dblp-lookup` to query DBLP
* `M-x doi-insert` to insert a BibTeX record by DOI
* `M-x dissemin-lookup` to show information about the open access status a
  particular DOI

Most of these commands work together: for example, `crossref-lookup` displays a
list of results in `biblio-selection-mode`.  In that mode, use:

* `c` or `M-w` to copy the BibTeX record of the current entry
* `i` or `C-y` to insert the BibTeX record of the current entry
* `o` to run an extended action, such as fetching a Dissemin record

## Examples

* To insert a clean BibTeX entry for [this paper](http://dx.doi.org/10.1145/2676726.2677006) in the current buffer, use
    ```
    M-x crossref-lookup RET fiat deductive delaware RET i
    ```
    (the last `i` inserts the BibTeX record of the currently selected entry in your buffer).

* To find publications by computer scientist Leslie Lamport, use `M-x dblp-lookup RET author:Lamport RET` (see more info about DBLP's syntax at <http://dblp.uni-trier.de/search/>)

* To check whether an article is available online for example Stallman's paper on EMACS, use `o` in the list of results. This only works with CrossRef at the moment. For example: `M-x crossref-lookup RET emacs stallman RET`, then press `o Dissemin RET`.

## Adding new backends

The extensibility mechanism is inspired by the one of company-mode. See the docstring of `biblio-backends`. Here is the definition of `biblio-dblp-backend`, for example:

```elisp
(defun biblio-dblp-backend (command &optional arg &rest _more)
  "A DBLP backend for biblio.el.
COMMAND, ARG, MORE: See `biblio-backends'."
  (interactive (list 'interactive))
  (pcase command
    (`name "DBLP")
    (`prompt "DBLP query: ")
    (`url (biblio-dblp--url arg))
    (`parse-buffer (biblio-dblp--parse-search-results))
    (`register (add-to-list 'biblio-backends #'biblio-dblp-backend))))

;;;###autoload
(add-hook 'biblio-init-hook #'biblio-dblp-backend)
```

Note how the autoload registers the backend without loading the entire file.  When `biblio-lookup` is called by the user, it will run all functions in `biblio-init-hook` with `'register`, and the `dblp` backend will be added to the list of backends add that point.

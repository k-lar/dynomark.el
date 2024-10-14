# dynomark.el

This package provides an intuitive way to run
[dynomark](https://github.com/k-lar/dynomark) queries within emacs.
It uses virtual text (overlays) to show the results within the fenced code blocks
where dynomark code should be.

## Features

**Commands:**  
- `dynomark-toggle` toggles the dynomark results for the current buffer.
- `dynomark-compile-in-new-buffer` "compiles" the dynomark code and replaces the
  queries with the results in a new buffer.

## Installation

You can install this package either by downloading the source code and adding it
to your load path, or by using a package manager like `straight.el` or `use-package` (with `vc-use-package`).

### Manual

```elisp
(add-to-list 'load-path "/path/to/dynomark.el")
(require 'dynomark)

;; Set up keybindings
(defun dynomark-setup-keybindings ()
  "Set up keybindings for `dynomark` in `markdown-mode`."
  (local-set-key (kbd "C-c t") 'dynomark-toggle)
  (local-set-key (kbd "C-c r") 'dynomark-compile-in-new-buffer))

;; Add the keybindings when markdown-mode is activated
(add-hook 'markdown-mode-hook 'dynomark-setup-markdown-mode-bindings)
```

### use-package

```elisp
(use-package dynomark
  :vc (:fetcher github :repo k-lar/dynomark.el) ;; uses vc-use-package
  ;; :vc (:url "https://github.com/k-lar/dynomark.el") ;; for emacs 30+
  :ensure t ;; to install the package if it's not already installed

  :commands (dynomark-toggle
             dynomark-compile-in-new-buffer)
  :hook (markdown-mode . dynomark-setup-keybindings))

(defun dynomark-setup-keybindings ()
  "Set up keybindings for `dynomark` in `markdown-mode`."
  (local-set-key (kbd "C-c t") 'dynomark-toggle)
  (local-set-key (kbd "C-c r") 'dynomark-compile-in-new-buffer))
```

## Usage

To use this package, you need to have a markdown file with fenced code blocks
with a language identifier of `dynomark`. The code blocks should contain the
query you want to run. For example:
````markdown
```dynomark
TASK FROM examples/ WHERE NOT CHECKED
```
````

When you run `dynomark-toggle` in the buffer, the results of the query will look like this:

````markdown
```dynomark
- [ ] Do the thing
- [ ] Do the other thing
- [ ] Do the last thing
```
````

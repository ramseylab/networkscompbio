# networkscompbio
Code for the class CS 446/546 - Networks in computational biology

## Emacs Usage

Install [The Emacs IPython Notebook](http://millejoh.github.io/emacs-ipython-notebook/) (EIN) from MELPA

    M-x list-packages

find `ein` and install.

Then [install Jupyter Notebook](http://jupyter.readthedocs.io/en/latest/install.html)

    # pip3 install --upgrade pip
    # pip3 install jupyter

And customize `.emacs`

    ;; Emacs IPython Notebook
    ;; https://github.com/millejoh/emacs-ipython-notebook
    (setq ein:jupyter-default-server-command "/usr/local/bin/jupyter")
    (add-hook 'ein:notebook-mode-hook
              (lambda ()
                (set-face-background 'ein:cell-input-area "unspecified-bg")))

To use EIN, execute `M-x ein:jupyter-server-start` and choose the appropriate directory.  Use the notebook list to edit notebooks.

Useful key combinations:

    Key        Function                         Description
    ------------------------------------------------------------------
    C-c '      ein:edit-cell-contents           Edit cell
    C-c C-c    ein:worksheet-execute-cell       Execute cell
               ein:worksheet-execute-all-cell   Execute all cells
    C-c C-n    ein:worksheet-goto-next-input    Go to next
    C-c C-p    ein:worksheet-goto-prev-input    Go to previous

Install missing Python 3 Packages with `pip3`, for example:

    # pip3 install pandas
    # pip3 install matplotlib
    # pip3 install python-igraph
    # pip3 install bintrees
    # pip3 install pympler
    # pip3 install pygraphviz

Run a Python 3 shell with `M-x python-shell-switch-to-shell RET /usr/bin/python3 -i RET y` or set the default interpreter `M-x set-variable RET python-shell-interpreter RET "python3" RET` to use `M-x run-python`. Run an IPython 3 shell with `M-x python-shell-switch-to-shell RET ipython3 --simple-prompt RET y`.

To revert undesirable changes, close open notebooks and then `git checkout -p -- classXX_name_python3.ipynb`.

To view local notebooks in the browser, navigate to [http://localhost:8888](http://localhost:8888). This may be necessary to debug or disable code that is not functional within Emacs such as images.

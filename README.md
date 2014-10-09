etags-update
============

Update etags on save.

Inspired by https://github.com/mattkeller/etags-update but I wanted to write my own to imporove my elisp.
This is simpler but shorter and is not a global mode since I don't use etags for everything. Also, it doesn't rely on an external perl file as I wanted everything done in elisp.

For example, I wanted etags for xslt. I set this up in ~/.ctags (I prefer exuberant-ctags to etags):
```
--langdef=xslt
--langmap=xslt:.xsl
--regex-xslt=/<xsl:template name="([^"]*)"/1/
--regex-xslt=/<xsl:template match="[^"]*"[ \t\n]+mode="([^"]*)"/1/
--regex-xslt=/<xsl:variable name="([^"]+)"/1/
```
Now ctags -e knows how to tag xsl files. Now I include this in my .emacs to set up the mode I edit xslt files with:
```elisp
(add-hook 'nxml-mode-hook
          (lambda ()
            (when (string-match-p "/my/xslt/project/path" (buffer-file-name))
              (visit-tags-table "~/Documents/learn/xslt/TAGS"  t)
              (require 'etags-update)
              (etags-update-mode))))
```
Now when I'm working on .xsl files in my project location, my TAGS file will be updated on file save.

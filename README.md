# homebrew-mozc-ut2
Homebrew formula script for mozc-ut2.

```
* mozc - Japanese Input Method  https://github.com/google/mozc
* mozc-ut - Arch Linux Package  https://aur.archlinux.org/packages/mozc-ut2
* Mozc UT2 Dictionay            http://www.geocities.jp/ep3797/mozc-ut2.html
```
### Installation
```
brew tap jhorology/mozc-ut2
brew install mozc-ut2 [options]
sudo sh /usr/local/opt/mozc-ut2/install-mozc-ut2.sh
```

To uninstall
```
sudo sh /usr/local/opt/mozc-ut2/uninstall-mozc-ut2.sh
brew uninstall mozc-ut2
brew untap jhorology/mozc-ut2
```
Options
```
--with-qt       Build with Qt5
--with-emacs    Build emacs support files
--with-tarball  Generate source tarball for Arch Linux (pkgbuild)
--with-ejdic    Generate the English-Japanese dictionary
--with-nicodic  Generate the Niconico dictionary
```
Using with emacs, need option --with-emacs
```
(require 'mozc); or (load-file "/usr/local/share/emacs/site-lisp/mozc.el")
(setq default-input-method "japanese-mozc")
```

### Notes
* Input Method module are need to be placed system-specific location, do not use 'brew linkapps'
* Using mozc for only emacs, don't need to register input method by control-panel.

### License
* This formula script is based on original mozcdic-ut2, license under GPL.
* For license information about mozc, refere to [google/mozc](https://github.com/google/mozc).
* For license information about Mozc UT Dictionary, refere to http://www.geocities.jp/ep3797/mozc-ut2.html

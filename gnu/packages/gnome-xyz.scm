;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2019 Leo Prikler <leo.prikler@student.tugraz.at>
;;; Copyright © 2019 Alexandros Theodotou <alex@zrythm.org>
;;; Copyright © 2019 Giacomo Leidi <goodoldpaul@autistici.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages gnome-xyz)
  #:use-module (guix build-system trivial)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages xml))

(define-public matcha-theme
  (package
    (name "matcha-theme")
    (version "2019-11-02")
    (source
      (origin
        (method git-fetch)
        (uri
          (git-reference
            (url "https://github.com/vinceliuice/matcha")
            (commit version)))
        (file-name (git-file-name name version))
        (sha256
          (base32
            "0wci9ahap8kynq8cbyxr7aba9ndb1d4kiq42xvzr34vw1rhcahrr"))))
    (build-system trivial-build-system)
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (source (assoc-ref %build-inputs "source"))
                (bash (assoc-ref %build-inputs "bash"))
                (coreutils (assoc-ref %build-inputs  "coreutils"))
                (themesdir (string-append out "/share/themes")))
           (setenv "PATH"
                   (string-append coreutils "/bin:"
                                  (string-append bash "/bin:")))
           (copy-recursively source (getcwd))
           (patch-shebang "Install")
           (mkdir-p themesdir)
           (invoke "./Install" "-d" themesdir)
           #t))))
    (inputs
     `(("gtk-engines" ,gtk-engines)))
    (native-inputs
     `(("bash" ,bash)
       ("coreutils" ,coreutils)))
    (synopsis "Flat design theme for GTK 3, GTK 2 and GNOME-Shell")
    (description "Matcha is a flat Design theme for GTK 3, GTK 2 and
Gnome-Shell which supports GTK 3 and GTK 2 based desktop environments
like Gnome, Unity, Budgie, Pantheon, XFCE, Mate and others.")
    (home-page "https://github.com/vinceliuice/matcha")
    (license license:gpl3+)))

(define-public delft-icon-theme
  (package
    (name "delft-icon-theme")
    (version "1.10")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/madmaxms/iconpack-delft.git")
             (commit (string-append "v" version))))
       (sha256
        (base32
         "0vw3yw9f9ygzfd2k3zrfih3r0vkzlhk1bmsk8sapvk7np24i1z9s"))
       (file-name (git-file-name name version))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (copy-recursively (assoc-ref %build-inputs "source") "icons")
         (substitute* "icons/Delft/index.theme"
           (("gnome") "Adwaita"))
         (delete-file "icons/README.md")
         (delete-file "icons/LICENSE")
         (delete-file "icons/logo.jpg")
         (copy-recursively "icons" (string-append %output "/share/icons")))))
    (home-page "https://www.gnome-look.org/p/1199881/")
    (synopsis "Continuation of Faenza icon theme with up to date app icons")
    (description "Delft is a fork of the popular icon theme Faenza with up to
date app icons.  It will stay optically close to the original Faenza icons,
which haven't been updated for some years.  The new app icons are ported from
the Obsidian icon theme.")
    (license license:gpl3)))

(define-public gnome-shell-extension-dash-to-dock
  (package
    (name "gnome-shell-extension-dash-to-dock")
    (version "66")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/micheleg/dash-to-dock.git")
                    (commit (string-append "extensions.gnome.org-v"
                                           version))))
              (sha256
               (base32
                "04krl6rxlp1qc97psraf2kwin7h0mx4c7pnfpi7vhplmvasrwkfh"))
              (file-name (git-file-name name version))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f
       #:make-flags (list (string-append "INSTALLBASE="
                                         (assoc-ref %outputs "out")
                                         "/share/gnome-shell/extensions"))
       #:phases
       (modify-phases %standard-phases
         (delete 'bootstrap)
         (delete 'configure))))
    (native-inputs
     `(("glib:bin" ,glib "bin")
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("glib" ,glib)))
    (synopsis "Transforms GNOME's dash into a dock")
    (description "This extension moves the dash out of the
overview, transforming it into a dock for easier application launching and
faster window switching.")
    (home-page "https://micheleg.github.io/dash-to-dock/")
    (license license:gpl2+)))

(define-public gnome-shell-extension-hide-app-icon
  (let ((commit "4188aa5f4ba24901a053a0c3eb0d83baa8625eab")
        (revision "0"))
    (package
      (name "gnome-shell-extension-hide-app-icon")
      (version (git-version "2.7" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url (string-append "https://github.com/michael-rapp"
                                   "/gnome-shell-extension-hide-app-icon.git"))
               (commit commit)))
         (sha256
          (base32
           "1i28n4bz6wrhn07vpxkr6l1ljyn7g8frp5xrr11z3z32h2hxxcd6"))
         (file-name (git-file-name name version))))
      (build-system gnu-build-system)
      (arguments
       '(#:tests? #f                ; no test target
         #:make-flags (list (string-append "EXTENSIONS_DIR="
                                           (assoc-ref %outputs "out")
                                           "/share/gnome-shell/extensions"))
         #:phases
         (modify-phases %standard-phases
           (delete 'configure)      ; no configure script
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((out (assoc-ref outputs "out"))
                     (pre "/share/gnome-shell/extensions/")
                     (dir "hide-app-icon@mrapp.sourceforge.com"))
                 (copy-recursively dir (string-append out pre dir))
                 #t))))))
      (native-inputs
       `(("glib" ,glib "bin")
         ("intltool" ,intltool)))
      (propagated-inputs
       `(("glib" ,glib)))
      (synopsis "Hide app icon from GNOME's panel")
      (description "This extension allows to hide the icon and/or title of the
currently focused application in the top panel of the GNOME shell.")
      (home-page
       "https://github.com/michael-rapp/gnome-shell-extension-hide-app-icon/")
      (license
        ;; README.md and LICENSE.txt disagree -- the former claims v3, the
        ;; latter v2.  No mention of "or later" in either place or in the code.
        (list license:gpl2
              license:gpl3)))))

(define-public gnome-shell-extension-dash-to-panel
  (package
    (name "gnome-shell-extension-dash-to-panel")
    (version "26")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/home-sweet-gnome/dash-to-panel.git")
                    (commit (string-append "v" version))))
              (sha256
               (base32
                "1phfx2pblygpcvsppsqqqflm7qnz46mqkw29hj0nv2dn69hf4xbc"))
              (file-name (git-file-name name version))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:make-flags (list (string-append "INSTALLBASE="
                                         (assoc-ref %outputs "out")
                                         "/share/gnome-shell/extensions")
                          (string-append "VERSION="
                                         ,(package-version
                                           gnome-shell-extension-dash-to-panel)))
       #:phases
       (modify-phases %standard-phases
         (delete 'bootstrap)
         (delete 'configure))))
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("glib" ,glib)
       ("glib" ,glib "bin")))
    (synopsis "Icon taskbar for GNOME Shell")
    (description "This extension moves the dash into the gnome main
panel so that the application launchers and system tray are combined
into a single panel, similar to that found in KDE Plasma and Windows 7+.")
    (home-page "https://github.com/home-sweet-gnome/dash-to-panel/")
    (license license:gpl2+)))

(define-public gnome-shell-extension-noannoyance
  (package
    (name "gnome-shell-extension-noannoyance")
    (version "5")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/BjoernDaase/noannoyance.git")
                    (commit "e37b5b3c31f577b4698bc6659bc9fec5ea9ac5d4")))
              (sha256
               (base32
                "0fa8l3xlh8kbq07y4385wpb908zm6x53z81q16xlmin97dln32hh"))
              (file-name (git-file-name name version))))
    (build-system trivial-build-system)
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((dst (string-append
                     (assoc-ref %outputs "out")
                     "/share/gnome-shell/extensions/"
                     "noannoyance@daase.net")))
           (mkdir-p dst)
           (copy-recursively (assoc-ref %build-inputs "source") dst)))))
    (synopsis "Removes 'Window is ready' annotation")
    (description "One of the many extensions, that remove this message.
It uses ES6 syntax and claims to be more actively maintained than others.")
    (home-page "https://extensions.gnome.org/extension/2182/noannoyance/")
    (license license:gpl2)))

(define-public numix-theme
  (package
    (name "numix-theme")
    (version "2.6.7")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/numixproject/numix-gtk-theme.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "12mw0kr0kkvg395qlbsvkvaqccr90cmxw5rrsl236zh43kj8grb7"))))
    (build-system gnu-build-system)
    (arguments
     '(#:make-flags (list (string-append "DESTDIR=" (assoc-ref %outputs "out")))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'check))))
    (native-inputs
     `(("glib:bin" ,glib "bin")             ; for glib-compile-schemas
       ("gnome-shell" ,gnome-shell)
       ("gtk+" ,gtk+)
       ("xmllint" ,libxml2)
       ("ruby-sass" ,ruby-sass)))
    (synopsis "Flat theme with light and dark elements")
    (description "Numix is a modern flat theme with a combination of light and
dark elements.  It supports GNOME, Unity, Xfce, and Openbox.")
    (home-page "https://numixproject.github.io")
    (license license:gpl3+)))

(define-public papirus-icon-theme
  (let ((version "0.0.0") ;; The package does not use semver
        (revision "0")
        (tag "20191201"))
    (package
      (name "papirus-icon-theme")
      (version (git-version version revision tag))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git")
               (commit tag)))
         (sha256
          (base32
           "0lnz1kmz28xh1f4slbsx7ycji5hgszyiyprbf5w5fbjhvi5gzw1h"))
         (file-name (git-file-name name version))))
      (build-system gnu-build-system)
    (arguments
     '(#:tests? #f
       #:make-flags (list (string-append "PREFIX=" (assoc-ref %outputs "out")))
       #:phases
       (modify-phases %standard-phases
         (delete 'bootstrap)
         (delete 'configure)
         (delete 'build))))
      (native-inputs
       `(("gtk+:bin" ,gtk+ "bin")))
      (home-page "https://git.io/papirus-icon-theme")
      (synopsis "Fork of Paper icon theme with a lot of new icons and a few extras")
      (description "Papirus is a fork of the icon theme Paper with a lot of new icons
and a few extra features.")
      (license license:gpl3))))

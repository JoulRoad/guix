;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 ng0 <ngillmann@runbox.com>
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

(define-module (gnu packages psyc)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages man)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages web))

(define-public perl-net-psyc
  (package
    (name "perl-net-psyc")
    (version "1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://perlpsyc.psyc.eu/"
                           "perlpsyc-" version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256
        (base32
         "1lw6807qrbmvzbrjn1rna1dhir2k70xpcjvyjn45y35hav333a42"))
       ;; psycmp3 currently depends on MP3::List and rxaudio (shareware),
       ;; we can add it back when this is no longer the case.
       (snippet '(delete-file "contrib/psycmp3"))))
    (build-system perl-build-system)
    (inputs
     `(("perl-curses" ,perl-curses)
       ("perl-io-socket-ssl" ,perl-io-socket-ssl)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure) ; No configure script
         ;; There is a Makefile, but it does not install everything
         ;; (leaves out psycion) and says
         ;; "# Just to give you a rough idea". XXX: Fix it upstream.
         (replace 'build
           (lambda _
             (zero? (system* "make" "manuals"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (doc (string-append out "/share/doc/perl-net-psyc"))
                    (man1 (string-append out "/share/man/man1"))
                    (man3 (string-append out "/share/man/man3"))
                    (bin (string-append out "/bin"))
                    (libpsyc (string-append out "/lib/psyc/ion"))
                    (libperl (string-append out "/lib/perl5/site_perl/"
                                            ,(package-version perl))))

               (copy-recursively "lib/perl5" libperl)
               (copy-recursively "lib/psycion" libpsyc)
               (copy-recursively "bin" bin)
               (install-file "cgi/psycpager" (string-append doc "/cgi"))
               (copy-recursively "contrib" (string-append doc "/contrib"))
               (copy-recursively "hooks" (string-append doc "/hooks"))
               (copy-recursively "sdj" (string-append doc "/sdj"))
               (install-file "README.txt" doc)
               (install-file "TODO.txt" doc)
               (copy-recursively "share/man/man1" man1)
               (copy-recursively "share/man/man3" man3)
               #t)))
         (add-after 'install 'wrap-programs
           (lambda* (#:key outputs #:allow-other-keys)
             ;; Make sure all executables in "bin" find the Perl modules
             ;; provided by this package at runtime.
             (let* ((out  (assoc-ref outputs "out"))
                    (bin  (string-append out "/bin/"))
                    (path (getenv "PERL5LIB")))
               (for-each (lambda (file)
                           (wrap-program file
                             `("PERL5LIB" ":" prefix (,path))))
                         (find-files bin "\\.*$"))
               #t))))))
    (description
     "@code{Net::PSYC} with support for TCP, UDP, Event.pm, @code{IO::Select} and
Gtk2 event loops.  This package includes 12 applications and additional scripts:
psycion (a @uref{http://about.psyc.eu,PSYC} chat client), remotor (a control console
for @uref{https://torproject.org,tor} router) and many more.")
    (synopsis "Perl implementation of PSYC protocol")
    (home-page "http://perlpsyc.psyc.eu/")
    (license (list license:gpl2
                   (package-license perl)
                   ;; contrib/irssi-psyc.pl:
                   license:public-domain
                   ;; bin/psycplay states AGPL with no version:
                   license:agpl3+))))

(define-public libpsyc
  (package
    (name "libpsyc")
    (version "20160913")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.psyced.org/files/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "14q89fxap05ajkfn20rnhc6b1h4i3i2adyr7y6hs5zqwb2lcmc1p"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("perl" ,perl)
       ("netcat" ,netcat)
       ("procps" ,procps)))
    (arguments
     `(#:make-flags
       (list "CC=gcc"
             (string-append "PREFIX=" (assoc-ref %outputs "out")))
       #:phases
       (modify-phases %standard-phases
         ;; The rust bindings are the only ones in use, the lpc bindings
         ;; are in psyclpc.  The other bindings are not used by anything,
         ;; the chances are high that the bindings do not even work,
         ;; therefore we do not include them.
         ;; TODO: Get a cargo build system in Guix.
         (delete 'configure)))) ; no configure script
    (home-page "http://about.psyc.eu/libpsyc")
    (description
     "@code{libpsyc} is a PSYC library in C which implements
core aspects of PSYC, useful for all kinds of clients and servers
including psyced.")
    (synopsis "PSYC library in C")
    (license license:agpl3+)))

;; This commit removes the historic bundled pcre, not released as a tarball so far.
(define-public psyclpc
  (let* ((commit "8bd51f2a4847860ba8b82dc79348ab37d516011e")
         (revision "1"))
  (package
    (name "psyclpc")
    (version (string-append "20160821-" revision "." (string-take commit 7)))
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "git://git.psyced.org/git/psyclpc")
                    (commit commit)))
              (file-name (string-append name "-" version "-checkout"))
              (sha256
               (base32
                "10w4kx9ygcv1lcmd7j4knvjiy8dac1y3hjfv3lhp67jpv6w3iagz"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; There are no tests/checks.
       #:configure-flags
       ;; If you have questions about this part, look at
       ;; "src/settings/psyced" and the ebuild.
       (list
        "--enable-use-tls=yes"
        "--enable-use-mccp" ; Mud Client Compression Protocol, leave this enabled.
        (string-append "--prefix="
                       (assoc-ref %outputs "out"))
        ;; src/Makefile: Set MUD_LIB to the directory which contains
        ;; the mud data. defaults to MUD_LIB = @libdir@
        (string-append "--libdir="
                       (assoc-ref %outputs "out")
                       "/opt/psyced/world")
        (string-append "--bindir="
                       (assoc-ref %outputs "out")
                       "/opt/psyced/bin")
        ;; src/Makefile: Set ERQ_DIR to directory which contains the
        ;; stuff which ERQ can execute (hopefully) savely.  Was formerly
        ;; defined in config.h. defaults to ERQ_DIR= @libexecdir@
        (string-append "--libexecdir="
                       (assoc-ref %outputs "out")
                       "/opt/psyced/run"))
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'chdir-to-src
           ;; We need to pass this as env variables
           ;; and manually change the directory.
           (lambda _
             (chdir "src")
             (setenv "CONFIG_SHELL" (which "sh"))
             (setenv "SHELL" (which "sh"))
             #t)))
       #:make-flags (list "install-all")))
    (inputs
     `(("zlib" ,zlib)
       ("openssl" ,openssl)
       ("pcre" ,pcre)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("bison" ,bison)
       ("gettext" ,gettext-minimal)
       ("help2man" ,help2man)
       ("autoconf" ,autoconf)
       ("automake" ,automake)))
    (home-page "http://lpc.psyc.eu/")
    (synopsis "psycLPC is a multi-user network server programming language")
    (description
     "LPC is a bytecode language, invented to specifically implement
multi user virtual environments on the internet.  This technology is used for
MUDs and also the psyced implementation of the Protocol for SYnchronous
Conferencing (PSYC).  psycLPC is a fork of LDMud with some new features and
many bug fixes.")
    (license license:gpl2))))

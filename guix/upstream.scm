;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2015 Alex Kost <alezost@gmail.com>
;;; Copyright © 2019 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (guix upstream)
  #:use-module (guix records)
  #:use-module (guix utils)
  #:use-module (guix discovery)
  #:use-module ((guix download)
                #:select (download-to-store url-fetch))
  #:use-module (guix gnupg)
  #:use-module (guix packages)
  #:use-module (guix ui)
  #:use-module (guix base32)
  #:use-module (guix gexp)
  #:use-module (guix store)
  #:use-module ((guix derivations)
                #:select (built-derivations derivation->output-path))
  #:use-module (guix monads)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-35)
  #:use-module (rnrs bytevectors)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:export (upstream-source
            upstream-source?
            upstream-source-package
            upstream-source-version
            upstream-source-urls
            upstream-source-signature-urls
            upstream-source-archive-types
            upstream-source-input-changes

            url-prefix-predicate
            coalesce-sources

            upstream-updater
            upstream-updater?
            upstream-updater-name
            upstream-updater-description
            upstream-updater-predicate
            upstream-updater-latest

            upstream-input-change?
            upstream-input-change-name
            upstream-input-change-type
            upstream-input-change-action
            changed-inputs

            %updaters
            lookup-updater

            download-tarball
            package-latest-release
            package-latest-release*
            package-update
            update-package-source))

;;; Commentary:
;;;
;;; This module provides tools to represent and manipulate a upstream source
;;; code, and to auto-update package recipes.
;;;
;;; Code:

;; Representation of upstream's source.  There can be several URLs--e.g.,
;; tar.gz, tar.gz, etc.  There can be correspond signature URLs, one per
;; source URL.
(define-record-type* <upstream-source>
  upstream-source make-upstream-source
  upstream-source?
  (package        upstream-source-package)        ;string
  (version        upstream-source-version)        ;string
  (urls           upstream-source-urls)           ;list of strings
  (signature-urls upstream-source-signature-urls  ;#f | list of strings
                  (default #f))
  (input-changes  upstream-source-input-changes
                  (default '()) (thunked)))

;; Representation of an upstream input change.
(define-record-type* <upstream-input-change>
  upstream-input-change make-upstream-input-change
  upstream-input-change?
  (name    upstream-input-change-name)    ;string
  (type    upstream-input-change-type)    ;symbol: regular | native | propagated
  (action  upstream-input-change-action)) ;symbol: add | remove

(define (changed-inputs package package-sexp)
  "Return a list of input changes for PACKAGE based on the newly imported
S-expression PACKAGE-SEXP."
  (match package-sexp
    ((and expr ('package fields ...))
     (let* ((input->name (match-lambda ((name pkg . out) name)))
            (new-regular
             (match expr
               ((path *** ('inputs
                           ('quasiquote ((label ('unquote sym)) ...)))) label)
               (_ '())))
            (new-native
             (match expr
               ((path *** ('native-inputs
                           ('quasiquote ((label ('unquote sym)) ...)))) label)
               (_ '())))
            (new-propagated
             (match expr
               ((path *** ('propagated-inputs
                           ('quasiquote ((label ('unquote sym)) ...)))) label)
               (_ '())))
            (current-regular
             (map input->name (package-inputs package)))
            (current-native
             (map input->name (package-native-inputs package)))
            (current-propagated
             (map input->name (package-propagated-inputs package))))
       (append-map
        (match-lambda
          ((action type names)
           (map (lambda (name)
                  (upstream-input-change
                   (name name)
                   (type type)
                   (action action)))
                names)))
        `((add regular
           ,(lset-difference equal?
                             new-regular current-regular))
          (remove regular
           ,(lset-difference equal?
                             current-regular new-regular))
          (add native
           ,(lset-difference equal?
                             new-native current-native))
          (remove native
           ,(lset-difference equal?
                             current-native new-native))
          (add propagated
           ,(lset-difference equal?
                             new-propagated current-propagated))
          (remove propagated
           ,(lset-difference equal?
                             current-propagated new-propagated))))))
    (_ '())))

(define (url-prefix-predicate prefix)
  "Return a predicate that returns true when passed a package where one of its
source URLs starts with PREFIX."
  (lambda (package)
    (define matching-uri?
      (match-lambda
        ((? string? uri)
         (string-prefix? prefix uri))
        (_
         #f)))

    (match (package-source package)
      ((? origin? origin)
       (match (origin-uri origin)
         ((? matching-uri?) #t)
         (_                 #f)))
      (_ #f))))

(define (upstream-source-archive-types release)
  "Return the available types of archives for RELEASE---a list of strings such
as \"gz\" or \"xz\"."
  (map file-extension (upstream-source-urls release)))

(define (coalesce-sources sources)
  "Coalesce the elements of SOURCES, a list of <upstream-source>, that
correspond to the same version."
  (define (same-version? r1 r2)
    (string=? (upstream-source-version r1) (upstream-source-version r2)))

  (define (release>? r1 r2)
    (version>? (upstream-source-version r1) (upstream-source-version r2)))

  (fold (lambda (release result)
          (match result
            ((head . tail)
             (if (same-version? release head)
                 (cons (upstream-source
                        (inherit release)
                        (urls (append (upstream-source-urls release)
                                      (upstream-source-urls head)))
                        (signature-urls
                         (let ((one (upstream-source-signature-urls release))
                               (two (upstream-source-signature-urls head)))
                           (and one two (append one two)))))
                       tail)
                 (cons release result)))
            (()
             (list release))))
        '()
        (sort sources release>?)))


;;;
;;; Auto-update.
;;;

(define-record-type* <upstream-updater>
  upstream-updater make-upstream-updater
  upstream-updater?
  (name        upstream-updater-name)
  (description upstream-updater-description)
  (pred        upstream-updater-predicate)
  (latest      upstream-updater-latest))

(define (importer-modules)
  "Return the list of importer modules."
  (cons (resolve-interface '(guix gnu-maintenance))
        (all-modules (map (lambda (entry)
                            `(,entry . "guix/import"))
                          %load-path)
                     #:warn warn-about-load-error)))

(define %updaters
  ;; The list of publically-known updaters.
  (delay (fold-module-public-variables (lambda (obj result)
                                         (if (upstream-updater? obj)
                                             (cons obj result)
                                             result))
                                       '()
                                       (importer-modules))))

(define (lookup-updater package updaters)
  "Return an updater among UPDATERS that matches PACKAGE, or #f if none of
them matches."
  (find (match-lambda
          (($ <upstream-updater> name description pred latest)
           (pred package)))
        updaters))

(define (package-latest-release package updaters)
  "Return an upstream source to update PACKAGE, a <package> object, or #f if
none of UPDATERS matches PACKAGE.  It is the caller's responsibility to ensure
that the returned source is newer than the current one."
  (match (lookup-updater package updaters)
    ((? upstream-updater? updater)
     ((upstream-updater-latest updater) package))
    (_ #f)))

(define (package-latest-release* package updaters)
  "Like 'package-latest-release', but ensure that the return source is newer
than that of PACKAGE."
  (match (package-latest-release package updaters)
    ((and source ($ <upstream-source> name version))
     (and (version>? version (package-version package))
          source))
    (_
     #f)))

(define (uncompressed-tarball name tarball)
  "Return a derivation that decompresses TARBALL."
  (define (ref package)
    (module-ref (resolve-interface '(gnu packages compression))
                package))

  (define compressor
    (cond ((or (string-suffix? ".gz" tarball)
               (string-suffix? ".tgz" tarball))
           (file-append (ref 'gzip) "/bin/gzip"))
          ((string-suffix? ".bz2" tarball)
           (file-append (ref 'bzip2) "/bin/bzip2"))
          ((string-suffix? ".xz" tarball)
           (file-append (ref 'xz) "/bin/xz"))
          ((string-suffix? ".lz" tarball)
           (file-append (ref 'lzip) "/bin/lzip"))
          (else
           (error "unknown archive type" tarball))))

  (gexp->derivation (file-sans-extension name)
                    #~(begin
                        (copy-file #+tarball #+name)
                        (and (zero? (system* #+compressor "-d" #+name))
                             (copy-file #+(file-sans-extension name)
                                        #$output)))))

(define* (download-tarball store url signature-url
                           #:key (key-download 'interactive))
  "Download the tarball at URL to the store; check its OpenPGP signature at
SIGNATURE-URL, unless SIGNATURE-URL is false.  On success, return the tarball
file name; return #f on failure (network failure or authentication failure).
KEY-DOWNLOAD specifies a download policy for missing OpenPGP keys; allowed
values: 'interactive' (default), 'always', and 'never'."
  (let ((tarball (download-to-store store url)))
    (if (not signature-url)
        tarball
        (let* ((sig  (download-to-store store signature-url))

               ;; Sometimes we get a signature over the uncompressed tarball.
               ;; In that case, decompress the tarball in the store so that we
               ;; can check the signature.
               (data (if (string-prefix? (basename url)
                                         (basename signature-url))
                         tarball
                         (run-with-store store
                           (mlet %store-monad ((drv (uncompressed-tarball
                                                     (basename url) tarball)))
                             (mbegin %store-monad
                               (built-derivations (list drv))
                               (return (derivation->output-path drv))))))))
          (let-values (((status data)
                        (gnupg-verify* sig data #:key-download key-download)))
            (match status
              ('valid-signature
               tarball)
              ('invalid-signature
               (warning (G_ "signature verification failed for '~a' (key: ~a)~%")
                        url data)
               #f)
              ('missing-key
               (warning (G_ "missing public key ~a for '~a'~%")
                        data url)
               #f)))))))

(define (find2 pred lst1 lst2)
  "Like 'find', but operate on items from both LST1 and LST2.  Return two
values: the item from LST1 and the item from LST2 that match PRED."
  (let loop ((lst1 lst1) (lst2 lst2))
    (match lst1
      ((head1 . tail1)
       (match lst2
         ((head2 . tail2)
          (if (pred head1 head2)
              (values head1 head2)
              (loop tail1 tail2)))))
      (()
       (values #f #f)))))

(define* (package-update/url-fetch store package source
                                   #:key key-download)
  "Return the version, tarball, and SOURCE, to update PACKAGE to
SOURCE, an <upstream-source>."
  (match source
    (($ <upstream-source> _ version urls signature-urls)
     (let*-values (((archive-type)
                    (match (and=> (package-source package) origin-uri)
                      ((? string? uri)
                       (let ((type (file-extension (basename uri))))
                         ;; Sometimes we have URLs such as
                         ;; "https://github.com/…/tarball/v0.1", in which case
                         ;; we must not consider "1" as the extension.
                         (and (or (string-contains type "z")
                                  (string=? type "tar"))
                              type)))
                      (_
                       "gz")))
                   ((url signature-url)
                    ;; Try to find a URL that matches ARCHIVE-TYPE.
                    (find2 (lambda (url sig-url)
                             ;; Some URIs lack a file extension, like
                             ;; 'https://crates.io/???/0.1/download'.  In that
                             ;; case, pick the first URL.
                             (or (not archive-type)
                                 (string-suffix? archive-type url)))
                           urls
                           (or signature-urls (circular-list #f)))))
       ;; If none of URLS matches ARCHIVE-TYPE, then URL is #f; in that case,
       ;; pick up the first element of URLS.
       (let ((tarball (download-tarball store
                                        (or url (first urls))
                                        (and (pair? signature-urls)
                                             (or signature-url
                                                 (first signature-urls)))
                                        #:key-download key-download)))
         (values version tarball source))))))

(define %method-updates
  ;; Mapping of origin methods to source update procedures.
  `((,url-fetch . ,package-update/url-fetch)))

(define* (package-update store package updaters
                         #:key (key-download 'interactive))
  "Return the new version, the file name of the new version tarball, and input
changes for PACKAGE; return #f (three values) when PACKAGE is up-to-date.
KEY-DOWNLOAD specifies a download policy for missing OpenPGP keys; allowed
values: 'always', 'never', and 'interactive' (default)."
  (match (package-latest-release* package updaters)
    ((? upstream-source? source)
     (let ((method (match (package-source package)
                     ((? origin? origin)
                      (origin-method origin))
                     (_
                      #f))))
       (match (assq method %method-updates)
         (#f
          (raise (condition (&message
                             (message (format #f (G_ "cannot download for \
this method: ~s")
                                              method)))
                            (&error-location
                             (location (package-location package))))))
         ((_ . update)
          (update store package source
                  #:key-download key-download)))))
    (#f
     (values #f #f #f))))

(define* (update-package-source package source hash)
  "Modify the source file that defines PACKAGE to refer to SOURCE, an
<upstream-source> whose tarball has SHA256 HASH (a bytevector).  Return the
new version string if an update was made, and #f otherwise."
  (define (update-expression expr replacements)
    ;; Apply REPLACEMENTS to package expression EXPR, a string.  REPLACEMENTS
    ;; must be a list of replacement pairs, either bytevectors or strings.
    (fold (lambda (replacement str)
            (match replacement
              (((? bytevector? old-bv) . (? bytevector? new-bv))
               (string-replace-substring
                str
                (bytevector->nix-base32-string old-bv)
                (bytevector->nix-base32-string new-bv)))
              ((old . new)
               (string-replace-substring str old new))))
          expr
          replacements))

  (let ((name        (package-name package))
        (version     (upstream-source-version source))
        (version-loc (package-field-location package 'version)))
    (if version-loc
        (let* ((loc         (package-location package))
               (old-version (package-version package))
               (old-hash    (origin-sha256 (package-source package)))
               (old-url     (match (origin-uri (package-source package))
                              ((? string? url) url)
                              (_ #f)))
               (new-url     (match (upstream-source-urls source)
                              ((first _ ...) first)))
               (file        (and=> (location-file loc)
                                   (cut search-path %load-path <>))))
          (if file
              ;; Be sure to use absolute filename.  Replace the URL directory
              ;; when OLD-URL is available; this is useful notably for
              ;; mirror://cpan/ URLs where the directory may change as a
              ;; function of the person who uploads the package.  Note that
              ;; package definitions usually concatenate fragments of the URL,
              ;; which is why we only attempt to replace a subset of the URL.
              (let ((properties (assq-set! (location->source-properties loc)
                                           'filename file))
                    (replacements `((,old-version . ,version)
                                    (,old-hash . ,hash)
                                    ,@(if (and old-url new-url)
                                          `((,(dirname old-url) .
                                             ,(dirname new-url)))
                                          '()))))
                (and (edit-expression properties
                                      (cut update-expression <> replacements))
                     version))
              (begin
                (warning (G_ "~a: could not locate source file")
                         (location-file loc))
                #f)))
        (begin
          (format (current-error-port)
                  (G_ "~a: ~a: no `version' field in source; skipping~%")
                  (location->string (package-location package))
                  name)))))

;;; upstream.scm ends here

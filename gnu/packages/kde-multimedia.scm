;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2019 Hartmut Goebel <h.goebel@crazy-compilers.com>
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

(define-module (gnu packages kde-multimedia)
  #:use-module (guix build-system qt)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages music)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xiph))

(define-public dragon
  (package
    (name "dragon")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/dragon-" version ".tar.xz"))
       (sha256
        (base32 "02l16k4sgrxbczxp8rlnxbylb5fmjh4zhl4xw55qxkvmvxnjy5zr"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("kdoctools" ,kdoctools)))
    (inputs
     `(("kconfig" ,kconfig)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcoreaddons" ,kcoreaddons)
       ("kcrash" ,kcrash)
       ("kdbusaddons" ,kdbusaddons)
       ("ki18n" ,ki18n)
       ("kio" ,kio)
       ("kjobwidgets" ,kjobwidgets)
       ("knotifications" ,knotifications)
       ("kparts" ,kparts)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kwindowsystem" ,kwindowsystem)
       ("kxmlgui" ,kxmlgui)
       ("oxygen-icons" ,oxygen-icons) ; default icon set
       ("phonon" ,phonon)
       ("phonon-backend-gstreamer" ,phonon-backend-gstreamer)
       ("qtbase" ,qtbase)
       ("solid" ,solid)))
    (home-page "https://kde.org/applications/multimedia/org.kde.dragonplayer")
    (synopsis "Simple video player")
    (description "Dragon Player is a multimedia player where the focus is on
simplicity, instead of features.  Dragon Player does one thing, and only one
thing, which is playing multimedia files.  It's simple interface is designed
not to get in your way and instead empower you to simply play multimedia
files.

This package is part of the KDE multimedia module.")
    (license ;; GPL for programs, FDL for documentation
     (list license:gpl2+ license:fdl1.2+))))

(define-public juk
  (package
    (name "juk")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/juk-" version ".tar.xz"))
       (sha256
        (base32 "0c1hrd1n4ah7qm8xr7bfswgbcmbvnnhai4bfawx6v6ab3frl7wvf"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("kcoreaddons" ,kcoreaddons)
       ("kcompletion" ,kcompletion)
       ("kconfig" ,kconfig)
       ("kcrash" ,kcrash)
       ("kdbusaddons" ,kdbusaddons)
       ("kdoctools" ,kdoctools)
       ("kglobalaccel" ,kglobalaccel)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kjobwidgets" ,kjobwidgets)
       ("kio" ,kio)
       ("knotifications" ,knotifications)
       ("ktextwidgets" ,ktextwidgets)
       ("kwallet" ,kwallet)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kwindowsystem" ,kwindowsystem)
       ("kxmlgui" ,kxmlgui)
       ("oxygen-icons" ,oxygen-icons) ; default icon set
       ("phonon" ,phonon)
       ("phonon-backend-gstreamer" ,phonon-backend-gstreamer)
       ("qtbase" ,qtbase)
       ("qtsvg" ,qtsvg)
       ("taglib" ,taglib)))
    (home-page "https://kde.org/applications/multimedia/org.kde.juk")
    (synopsis "Music jukebox / music player")
    (description "JuK is a powerful music player capable of managing a large
music collection.

Some of JuK's features include:
@itemize
@item Music collection, playlists, and smart playlists
@item Tag editing support, including the ability to edit multiple files at once
@item Tag-based music file organization and renaming
@item CD burning support using k3b
@item Album art using Google Image Search
@end itemize

This package is part of the KDE multimedia module.")
    (license license:gpl2+)))

(define-public k3b
  (package
    (name "k3b")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/k3b-" version ".tar.xz"))
       (sha256
        (base32 "08rbiy1hz650srdksr7ciq8dpcz20wczs22613pghrpgm5zsczhr"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("pkg-config" ,pkg-config)
       ("kdoctools" ,kdoctools)))
    (inputs
     `(("ffmpeg" ,ffmpeg)
       ("flac" ,flac)
       ("karchive" ,karchive)
       ("kcmutils" ,kcmutils)
       ("kconfig" ,kconfig)
       ("kcoreaddons" ,kcoreaddons)
       ("kfilemetadata" ,kfilemetadata)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kio" ,kio)
       ("kjobwidgets" ,kjobwidgets)
       ("knewstuff" ,knewstuff)
       ("knotifications" ,knotifications)
       ("knotifyconfig" ,knotifyconfig)
       ("kservice" ,kservice)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kxmlgui" ,kxmlgui)
       ("lame" ,lame)
       ("libdvdread" ,libdvdread)
       ;; TODO: LibFuzzer
       ("libiconv" ,libiconv)
       ("libkcddb" ,libkcddb)
       ("libmad" ,libmad)
       ("libmpcdec" ,libmpcdec) ;; FIXME: why does cmake not find this?
       ;;("libmusicbrainz" ,libmusicbrainz) ; wants old version 2
       ("libsamplerate" ,libsamplerate)
       ("libsndfile" ,libsndfile)
       ("libvorbis" ,libvorbis)
       ("oxygen-icons" ,oxygen-icons) ; default icon set
       ("qtbase" ,qtbase)
       ("qtwebkit" ,qtwebkit)
       ("shared-mime-info" ,shared-mime-info)
       ("solid" ,solid)
       ("taglib" ,taglib)))
    (home-page "https://kde.org/applications/multimedia/org.kde.k3b")
    (synopsis "Sophisticated CD/DVD burning application")
    (description "K3b is CD-writing software which intends to be feature-rich
and provide an easily usable interface.  Features include burning audio CDs
from .WAV and .MP3 audio files, configuring external programs and configuring
devices.")
    (license ;; GPL for programs, FDL for documentation
     (list license:gpl2+ license:fdl1.2+))))

(define-public libkcddb
  (package
    (name "libkcddb")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/libkcddb-" version ".tar.xz"))
       (sha256
        (base32 "1rla9sfzpdfiki0p265ga6d1axqpq37825maaw85hm84mg7hkzjn"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("kdoctools" ,kdoctools)))
    (inputs
     `(("kcodecs" ,kcodecs)
       ("kconfig" ,kconfig)
       ("ki18n" ,ki18n)
       ("kio" ,kio)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("libmusicbrainz" ,libmusicbrainz)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:tests? #f)) ; Most tests require network
    (home-page "https://cgit.kde.org/libkcddb.git")
    (synopsis "CDDB library for KDE Platform (runtime)")
    (description "A library for retrieving and sending cddb information.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

---
title: ROOT installation on OS X
author: Kevin
---

In particle physics, when it comes to data analysis, [CERN's
`ROOT`](http://root.cern.ch/) often is the tool of choice. It is a big and
powerful framework that can do a lot of magical things. In this post, I don't
want to discuss its advantages or disadvantages but rather explain how I
install it on Mac OS and why I do so.

<!-- more -->

There are always different ways to install `ROOT`. Although you might almost
always want to work with the latest production version, be warned that new
releases sometimes break compatibility with older code. You will have to decide
for yourself whether you want to [install via MacPorts](#the-easy-way-macports)
and get to work quickly or [compile from source](#installation-from-source) and
be able to maintain multiple versions on your system.


## The easy way: MacPorts

If you don't care about multiple versions and just want to get started, you can
install `ROOT` via [MacPorts](http://www.macports.org/) with the following
command. This will, however, install `ROOT` into your `$PATH` which might have
unwanted side-effects.

```bash
sudo port install root
```

Additional features can be activated by adding `+feature` to the above line.
The possible features are

```
clang30 clang31 clang32 clang33 clang34 clang35
gcc43 gcc44 gcc45 gcc46 gcc47 gcc48 gcc49
```

for manually choosing the compiler version,

```
python26 python27 python31 python32 python33 python34
```

for specifying a Python version,

```
ruby
```

for enabling support for Ruby,

```
mariadb
mysql mysql51 mysql55
odbc
postgresql90 postgresql92
sqlite3
```

for adding database support, and a myriad of other options e.g for GUI
frameworks or the TMVA framework for multivariate analysis:

```
avahi cocoa debug fftw3 fitsio graphviz gsl ldap minuit2
opengl percona pythia qt_mac roofit ruby soversion ssl
tmva x11 xml xrootd
```

## Installation from Source

The following instructions are tested on OS X 10.9 and 10.8 and are most likely
to also work in 10.7. Installation on 10.6 might be different but why would you
be using such an old operating system, anyway?


### Prerequisites

You will have to install Apple's XCode and the XCode Command Line Tools.
[XQuartz](https://xquartz.macosforge.org/landing/), the Mac OS implementation
of the X11 framework, is mandatory.


### From source

_A more comprehensive documentation can be found [on the official
website](http://root.cern.ch/drupal/content/installing-root-source)_.

The following lines will install a basic version of `ROOT 5.34.18` to
`/opt/ROOT/5.34.18`.

```bash
curl -O ftp://root.cern.ch/root/root_v5.34.18.source.tar.gz
tar xvzf root_v5.34.18.source.tar.gz
cd root
./configure --prefix=/opt/ROOT/5.34.18/
make
sudo make install
```

If you want to speed up the compilation, use `make -jN` where `N` should be 1.5
times the number of cores on your machine, e.g. `make -j3` on my old dual-core
MacBook Pro.

The `configure` step is where you can introduce additional options e.g. enable
advanced packages or define custom paths. A comprehensive list of options can
be obtained by running

```bash
./configure --help
```

My personal configuration looks something like this:

```bash
./configure macosx64 \
    --prefix=/opt/ROOT/5.34.18 \
    --with-clang \
    --enable-roofit \
    --enable-cocoa \
    --enable-c++11 \
    --with-python-incdir=/opt/local/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7/ \
    --with-python-libdir=/opt/local/Library/Frameworks/Python.framework/Versions/2.7/lib/
```

The last to lines ensure that the MacPorts version of Python 2.7 is used. If
you want to do the same, make sure Python 2.7 is the active version via

```bash
sudo port select python python27
```

### Set up

Once the installation is finished, you can set up `ROOT` by running

```bash
cd /opt/ROOT/5.34.18
source bin/thisroot.sh
```

Afterwards, typing

```bash
root
```

should start the interactive interpreter.

```
  *******************************************
  *                                         *
  *        W E L C O M E  to  R O O T       *
  *                                         *
  *   Version   5.34/18     14 March 2014   *
  *                                         *
  *  You are welcome to visit our Web site  *
  *          http://root.cern.ch            *
  *                                         *
  *******************************************

ROOT 5.34/18 (v5-34-18@v5-34-18, Mar 14 2014, 16:29:50 on macosx64)

CINT/ROOT C/C++ Interpreter version 5.18.00, July 2, 2010
Type ? for help. Commands must be C++ statements.
Enclose multiple statements between { }.
root [0]
```

You can exit by typing `.q`.

[Go to the corresponding issue on GitHub, in order to discuss this
article.](https://github.com/kdungs/dun.gs/issues/2)

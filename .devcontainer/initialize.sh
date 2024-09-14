#!/bin/bash
set -euxo pipefail

sudo apt install -y vim perl-doc cpanminus liblocal-lib-perl
curl -L https://install.perlbrew.pl | bash
grep -q -- '-Mlocal::lib' ~/.bashrc || echo "eval \"\$(perl -I\$HOME/perl5/lib/perl5 -Mlocal::lib)\"" >>~/.bashrc
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

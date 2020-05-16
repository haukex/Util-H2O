#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests=>3;
use Util::H2O;

## no critic (ProhibitBacktickOperators)

my ($initial) = `ps -orss $$`=~/\bRSS\s+(\d+)\b/;

for (1..1000) { my $h = { map {$_=>$_} 1..1000 } }

my ($normal) = `ps -orss $$`=~/RSS\s+(\d+)/;
ok $normal < $initial+1000, 'memory growth after normal hashrefs ('.($normal-$initial).'<1000)';

for (1..1000) { h2o { map {$_=>$_} 1..1000 } }

# if we didn't have our DESTROY, we'd see a memory growth several orders of magnitude greater
my ($after) = `ps -orss $$`=~/RSS\s+(\d+)/;
ok $after < $normal+2000, 'memory growth after h2o hashrefs ('.($after-$normal).'<2000)';

for (1..1000) { h2o(-meth, { map {$_=>sub{$_}} 1..1000 })->$_ }

my ($after2) = `ps -orss $$`=~/RSS\s+(\d+)/;
ok $after2 < $after+500, 'memory growth after h2o with methods ('.($after2-$after).'<500)';

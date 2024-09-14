#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests=>1;
use Util::H2O;
use Util::H2O::Also;
use Benchmark 'cmpthese';

my %hash = ( Hello=>'World' );

my $o1 = h2o {%hash};
my $o2 = Util::H2O::Also->new({%hash});

cmpthese(-2, {
    'H2O'  => sub { $o1->Hello },
    'Also' => sub { $o2->Hello },
});

pass 'TODO';

done_testing;
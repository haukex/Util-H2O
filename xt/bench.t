#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests=>1;
use Util::H2O;
use Util::H2O::Also;
use Benchmark qw/ timethese cmpthese /;

my %hash = ( Hello=>'World' );

my $o1 = h2o {%hash};
my $o2 = Util::H2O::Also->new({%hash});

my $r = timethese(-2, {
    'H2O'  => sub { $o1->Hello },
    'Also' => sub { $o2->Hello },
});
cmpthese $r;

my $ratio = $$r{H2O}->iters / $$r{Also}->iters;
ok $ratio > 5.5, 'expect Util::H2O to be ~6x faster than Util::H2O::Also, actual ratio '
    .sprintf('%.2f', $ratio);

done_testing;
#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Util::H2O::Also>.

=head1 Author, Copyright, and License

Copyright (c) 2024 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use Test::More; #TODO: tests=>1;

#TODO: sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)
#TODO: sub warns (&) { my @w; { local $SIG{__WARN__} = sub { push @w, shift }; shift->() } @w }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn)

## no critic (RequireTestLabels)

diag "This is Perl $] at $^X on $^O";
BEGIN { require_ok 'Util::H2O::Also' }
is $Util::H2O::Also::VERSION, '0.26';

done_testing;

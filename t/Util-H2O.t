#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Util::H2O>.

=head1 Author, Copyright, and License

Copyright (c) 2020 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use Test::More tests=>40;
use Scalar::Util qw/blessed/;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)

## no critic (RequireTestLabels)

diag "This is Perl $] at $^X on $^O";
BEGIN { use_ok 'Util::H2O' }
is $Util::H2O::VERSION, '0.01';

my $PACKRE = qr/\AUtil::H2O::_[0-9A-Fa-f]+\z/;

my $hash = { foo => "bar", x => "y" };
my $o1 = h2o $hash, qw/ more keys /;
is $o1, $hash;
like blessed($o1), $PACKRE;
is $o1->foo, 'bar';
is $o1->x, 'y';
ok exception { $o1->blah };
is $o1->x("z"), 'z';
is $o1->x, 'z';
is $o1->more, undef;
is $o1->keys, undef;
is $o1->more("quz"), 'quz';
is $o1->more, 'quz';
is_deeply $hash, { foo=>'bar', x=>'z', more=>'quz' };
is $o1->keys(undef), undef;
is_deeply $hash, { foo=>'bar', x=>'z', more=>'quz', keys=>undef };

my $o2 = { hello => { perl => "world!" }, x=>{y=>{z=>"foo"}} };
h2o -recurse, $o2;
is $o2->hello->perl, "world!";
is $o2->x->y->z, "foo";
like blessed($o2->x), $PACKRE;
like blessed($o2->x->y), $PACKRE;
note explain $o2;

my $o3 = h2o -recurse, { foo => { bar => "quz" } }, 'xyz';
is $o3->xyz, undef;
is $o3->foo->bar, 'quz';
ok exception { $o3->foo->xyz };

my $code = sub {};
my $o4 = h2o { a=>[], h=>{}, c=>$code };
is ref $o4->a, 'ARRAY';
is ref $o4->h, 'HASH';
is ref $o4->c, 'CODE';
is $o4->c, $code;

my $o5 = h2o -meth, { abc => 123, def => sub { $_[0]->abc(789); 456 } };
is $o5->abc, 123;
is $o5->def, 456;
is $o5->abc, 789;

my $o6 = h2o -meth, -recurse, { a => { b=>"c", d=>sub{"e"} }, f=>sub{"g"} };
is $o6->a->b, 'c';
is ref $o6->a->d, 'CODE';
is $o6->f, 'g';

ok exception { h2o() };
ok exception { h2o("blah") };
ok exception { h2o(undef) };
ok exception { h2o([]) };
ok exception { h2o(-meth,-recurse) };
ok exception { h2o(bless {}, "SomeClass") };
ok exception { h2o({DESTROY=>'foo'}) };

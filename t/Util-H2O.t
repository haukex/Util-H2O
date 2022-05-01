#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Util::H2O>.

=head1 Author, Copyright, and License

Copyright (c) 2020-2022 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use Test::More tests => 291;
use Scalar::Util qw/blessed/;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)
sub warns (&) { my @w; { local $SIG{__WARN__} = sub { push @w, shift }; shift->() } @w }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn)

## no critic (RequireTestLabels)

diag "This is Perl $] at $^X on $^O";
BEGIN { use_ok 'Util::H2O' }
is $Util::H2O::VERSION, '0.16';

diag "If all tests pass, you can ignore the \"this Perl is too old\" warnings"
	if $] lt '5.008009';

my $PACKRE = $Util::H2O::_PACKAGE_REGEX;  ## no critic (ProtectPrivateVars)

{
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
}
{
	my $o2 = { hello => { perl => "world!" }, x=>{y=>{z=>"foo"}} };
	h2o -recurse, $o2;
	is $o2->hello->perl, "world!";
	is $o2->x->y->z, "foo";
	like blessed($o2->x), $PACKRE;
	like blessed($o2->x->y), $PACKRE;
	note explain $o2;
}

# -recurse
{
	my $o3 = h2o -recurse, { foo => { bar => "quz" } }, 'xyz';
	is $o3->xyz, undef;
	is $o3->foo->bar, 'quz';
	ok exception { $o3->foo->xyz };
}
{
	my $code = sub {};
	my $o4 = h2o { a=>[], h=>{}, c=>$code };
	is ref $o4->a, 'ARRAY';
	is ref $o4->h, 'HASH';
	is ref $o4->c, 'CODE';
	is $o4->c, $code;
}
{
	my $o = h2o -recurse, { foo => { bar => "quz" } };
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { $o->{abc} = 123 };
		ok exception { $o->foo->{def} = 456 };
	}
	my $o2 = h2o -recurse, -nolock, { foo => { bar => "quz" } };
	$o2->{abc} = 123;
	$o2->foo->{def} = 456;
	is_deeply [sort keys %$o2], [qw/ abc foo /];
	is_deeply [sort keys %{$o2->foo}], [qw/ bar def /];
}

# o2h
{
	BEGIN { use_ok 'Util::H2O', 'o2h' }
	my $o = h2o -recurse, { a=>[ h2o {abc=>123} ], h=>{ x=>'y', z=>undef }, c=>sub {} };
	like blessed($o), $PACKRE;
	like blessed($o->h), $PACKRE;
	is $o->h->x, 'y';
	is $o->a->[0]->abc, 123;
	$o->h->z({ foo => h2o {def=>456} });
	is ref $o->h->z, 'HASH';
	is $o->h->z->{foo}->def, 456;
	my $h = o2h $o;
	is ref $h, 'HASH';
	is ref $h->{a}, 'ARRAY';
	like blessed($h->{a}[0]), $PACKRE;
	is ref $h->{h}, 'HASH';
	is ref $h->{h}{z}, 'HASH';
	like blessed($h->{h}{z}{foo}), $PACKRE;
	is $h->{h}{z}{foo}->def, 456;
	is ref $h->{c}, 'CODE';
	is $h->{h}{x}, 'y';
}
# o2h + -lock + -ro
{
	my $o = h2o -recurse, -lock=>1, -ro, { abc => { def => { ghi => 555 } } };
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $o->{zzz} };
		ok exception { my $y = $o->{abc}{def}{yyy} };
	}
	my $h = o2h $o;
	is ref $h, 'HASH';
	is ref $h->{abc}{def}, 'HASH';
	$h->{zzz} = 543;
	$h->{abc}{def}{ghi} = 777;
	is_deeply $h, { abc => { def => { ghi => 777 } }, zzz => 543 };
}
# o2h + -meth
{
	my $o = h2o -meth, { foo => "bar", quz => sub { "baz" } };
	is $o->foo, "bar";
	is $o->quz, "baz";
	my $h = o2h $o;
	is_deeply $h, { foo => "bar" };
}

# -meth
{
	my $o5 = h2o -meth, { abc => 123, def => sub { $_[0]->abc(789); 456 } };
	is $o5->abc, 123;
	is $o5->def, 456;
	is $o5->abc, 789;
}
{
	my $o6 = h2o -meth, -recurse, { a => { b=>"c", d=>sub{"e"} }, f=>sub{"g"} };
	is $o6->a->b, 'c';
	is ref $o6->a->d, 'CODE';
	is $o6->f, 'g';
}
{
	my $o = h2o -meth, { x=>111, y=>sub{222} };
	is $o->x, 111;
	is $o->y, 222;
	is_deeply [sort keys %$o], [qw/ x /];
	is $o->{x}, 111;
	SKIP: {
		skip "Won't work on old Perls", 1 if $] lt '5.008009';
		ok exception { my $x = $o->{y} };
	}
}
{
	my $o = h2o -meth, { x=>111, y=>sub{222} }, qw/y/;
	is $o->x, 111;
	is $o->y, 222;
	is_deeply [sort keys %$o], [qw/ x /];
	$o->{y} = 333;
	is_deeply $o, { x=>111, y=>333 };
	is $o->y, 222;
}
{
	my $h = { foo => 123, bar => sub {} };
	h2o -meth, $h;
	is_deeply $h, { foo => 123 };
}

# -class
{
	my $dest=0;
	my $o7 = h2o -class=>'Foo::Bar', -meth,
		{ ijk=>'nop', rst => sub { $_[0]->ijk('wxy'); 'efg' },
			DESTROY=>sub{$dest++} };
	isa_ok $o7, 'Foo::Bar';
	is $o7->ijk, 'nop';
	is $o7->rst, 'efg';
	is $o7->ijk, 'wxy';
	is $dest, 0;
	$o7 = undef;
	is $dest, 1;
	my $o7a = bless {}, 'Foo::Bar';
	is $o7a->ijk, undef;
	is $o7a->rst, 'efg';
	is $o7a->ijk, 'wxy';
}

# -isa
{
	sub get_isa {
		my $x = shift;
		$x = ref $x if ref $x;
		no strict 'refs';  ## no critic (ProhibitNoStrict)
		return \@{$x.'::ISA'};
	}
	{ package IsaTest2;  ## no critic (ProhibitMultiplePackages)
		sub foo { return "foo" }
	}
	{ package IsaTest3;  ## no critic (ProhibitMultiplePackages)
		our @ISA = ('IsaTest2');  ## no critic (ProhibitExplicitISA)
		sub bar { return "bar" }
	}
	{ package IsaTest5;  ## no critic (ProhibitMultiplePackages)
		sub quz { return "quz" }
	}
	my $o1 = h2o {};
	is_deeply get_isa($o1), [];
	h2o -class=>'IsaTest1', {};
	is_deeply \@IsaTest1::ISA, [];
	my $o2 = h2o -isa=>'IsaTest2', {};
	is_deeply get_isa($o2), ['IsaTest2'];
	isa_ok $o2, 'IsaTest2';
	ok $o2->can("foo");
	is $o2->foo, "foo";
	h2o -classify=>'IsaTest4', -isa=>'IsaTest3', {
		foo => sub { "Foo!" } };
	my $o3 = IsaTest4->new();
	isa_ok $o3, 'IsaTest4';
	isa_ok $o3, 'IsaTest3';
	isa_ok $o3, 'IsaTest2';
	is_deeply \@IsaTest4::ISA, ['IsaTest3'];
	is $o3->bar, "bar";
	is $o3->foo, "Foo!";
	my $o4 = h2o -isa=>['IsaTest5','IsaTest3'], {};
	ok $o4->can("foo");
	ok $o4->can("bar");
	ok $o4->can("quz");
}

# -clean
sub checksym {
	my $s = shift;
	my ($p,$n) = $s=~/\A(.+::)?(\w+)\z/ or die $s;  ## no critic (RequireCarping)
	my $t = defined $p ? do { no strict 'refs'; \%{$p} } : \%::;  ## no critic (ProhibitNoStrict)
	return exists $t->{$n.'::'};
}
{
	my $o = h2o {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok !checksym $c;
}
{
	my $o = h2o -clean=>0, {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok checksym $c;
}
{
	my $o = h2o -class=>'TestClean1', {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok checksym $c;
}
{
	my $o = h2o -class=>'TestClean2', -clean=>1, {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok !checksym $c;
}

# -new
{
	my $o = h2o -new, {};
	my $on = $o->new;
	isa_ok $on, ref $o;
}
{
	my $n = h2o -class=>'Quz', -new, {}, qw/ abc /;
	isa_ok $n, 'Quz';
	my $n2 = new_ok 'Quz';
	is $n2->abc, undef;
	my $n3 = $n2->new(abc=>444);
	is $n3->abc, 444;
	like exception { Quz->new(abc=>4,5) }, qr/\bOdd\b/;
	like exception { Quz->new(def=>4) }, qr/\bUnknown argument\b/i;
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $n->{new} };
		ok exception { my $x = $n->{DESTROY} };
	}
}
{
	my $o = h2o -meth, -new, { x=>111, y=>sub{222} }, qw/y/;
	my $n = $o->new( x=>333, y=>444 );
	is_deeply $n, { x=>333, y=>444 };
	is $n->y, 222;
	is $n->{y}, 444;
	my $n2 = $o->new( y=>sub{555} );
	is $n2->x, undef;
	is $n2->y, 222;
	is $n2->{y}->(), 555;
}

# -classify
{
	my $o = h2o -classify=>'Quz::Baz', { abc => 123, def => sub { $_[0]->abc(789); 456 } };
	is $o->abc, 123;
	is $o->def, 456;
	is $o->abc, 789;
	my $n = new_ok 'Quz::Baz';
	is $n->abc, undef;
	is $n->def, 456;
	is $n->abc, 789;
	my $n2 = $o->new( abc=>333 );
	is $n2->abc, 333;
	is $n2->def, 456;
	is $n2->abc, 789;
}
# -classify into current package
{
	{
		package Yet::Another;  ## no critic (ProhibitMultiplePackages)
		use Util::H2O;
		h2o -classify, { hello=>sub{"World!"} }, qw/abc/;
		sub test { return "<".shift->abc.">" }
	}
	my $o = new_ok 'Yet::Another', [ abc=>"def" ];
	is $o->hello, "World!";
	is $o->test, "<def>";
	ok exists &Yet::Another::h2o;
}
SKIP: {
	skip "Won't work on really old Perls", 2 if $] lt '5.008';
	my @w = warns {
		my $x = h2o -clean=>1, -classify, {};
		isa_ok $x, 'main';
	};
	is grep({/\brefusing to delete package\b/i} @w), 1;
}

# -lock / -nolock
{
	my $o = h2o { foo=>123 }, qw/ bar /;
	is $o->{foo}, 123;
	is $o->{bar}, undef;
	is_deeply [sort keys %$o], [qw/ foo /];
	$o->{bar} = 456;
	is $o->{bar}, 456;
	is_deeply [sort keys %$o], [qw/ bar foo /];
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $o->{quz} };
		ok exception { $o->{quz} = 789 };
	}
}
{
	my $o = h2o -lock=>1, { foo=>123 }, qw/ bar /;
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $o->{quz} };
		ok exception { $o->{quz} = 789 };
	}
}
{
	my $o = h2o -lock=>0, { foo=>123 }, qw/ bar /;
	is $o->{foo}, 123;
	is $o->{bar}, undef;
	is_deeply [sort keys %$o], [qw/ foo /];
	$o->{bar} = 456;
	is $o->{quz}, undef;
	is $o->{bar}, 456;
	is_deeply [sort keys %$o], [qw/ bar foo /];
	$o->{quz} = 789;
	is $o->{quz}, 789;
	is_deeply [sort keys %$o], [qw/ bar foo quz /];
	ok exception { my $x = $o->quz };
}
{
	my $o = h2o -nolock, { foo=>123 }, qw/ bar /;
	is $o->{foo}, 123;
	is $o->{bar}, undef;
	is_deeply [sort keys %$o], [qw/ foo /];
	$o->{bar} = 456;
	is $o->{quz}, undef;
	is $o->{bar}, 456;
	is_deeply [sort keys %$o], [qw/ bar foo /];
	$o->{quz} = 789;
	is $o->{quz}, 789;
	is_deeply [sort keys %$o], [qw/ bar foo quz /];
	ok exception { my $x = $o->quz };
}
{
	h2o -class=>'Baz', -new, {}, qw/ abc /;
	my $n = Baz->new(abc=>123);
	if ($] lt '5.008009') {
		$n->{def} = 456;
		is_deeply [sort keys %$n], [qw/ abc def /];
		pass 'dummy'; # so the number of tests still fits
	}
	else {
		ok exception { $n->{def} = 456 };
		is_deeply [sort keys %$n], [qw/ abc /];
	}
}
{
	h2o -class=>'Baz2', -new, -nolock, {}, qw/ abc /;
	my $n = Baz2->new(abc=>123);
	$n->{def} = 456;
	is_deeply [sort keys %$n], [qw/ abc def /];
}

# -ro
SKIP: {
	skip "Won't work on old Perls", 36 if $] lt '5.008009';
	my $o = h2o -ro, { foo=>123, bar=>undef };
	is $o->foo, 123;
	is $o->bar, undef;
	ok exception { $o->foo(456) };
	ok exception { $o->bar(789) };
	ok exception { $o->{foo} = 456 };
	ok exception { $o->{bar} = 789 };
	ok exception { $o->{quz} = 111 };
	is $o->foo, 123;
	is $o->bar, undef;
	is_deeply [sort keys %$o], [qw/ bar foo /];

	my $or = h2o -ro, -recurse, { foo => { bar => 'quz' } };
	ok exception { $or->foo(123) };
	ok exception { $or->foo->bar(456) };
	ok exception { $or->{foo} = 123 };
	ok exception { $or->{foo}{bar} = 456 };
	ok exception { $or->foo->{bar} = 456 };

	my $on = h2o -ro, -new, {}, qw/foo bar/;
	ok exception { $on->{foo} = 'x' };
	ok exception { $on->{bar} = 'y' };
	ok exception { $on->foo("x") };
	is_deeply [%$on], [];
	is $on->foo, undef;
	is $on->bar, undef;
	my $onn = $on->new(foo=>'quz');
	isa_ok $onn, ref $on;
	ok exception { $onn->{foo} = 'x' };
	ok exception { $onn->{bar} = 'y' };
	ok exception { $onn->foo("x") };
	is_deeply [%$onn], [ foo=>'quz' ];
	is $onn->foo, 'quz';
	is $onn->bar, undef;

	h2o -classify=>'ReadOnlyFoo', -ro, {
			add => sub { $_[0]->x + $_[0]->y },
		}, qw/ x y /;
	my $x = ReadOnlyFoo->new(x=>123, y=>456);
	is $x->add, 579;
	ok exception { $x->x(111) };
	ok exception { $x->y(222) };
	ok exception { $x->{x}=111 };
	ok exception { $x->{y}=222 };
	is $x->add, 579;

	ok exception { h2o -ro, { foo=>123 }, qw/ bar / };
	ok exception { h2o -ro, -nolock, { foo=>123 } };
}

# -destroy
{
	my $dest=0;
	my $o1 = h2o -destroy=>sub{$dest++}, {};
	is $dest, 0;
	$o1=undef;
	is $dest, 1;
	my $o2 = h2o -new, -destroy=>sub{$dest++}, {};
	is $dest, 1;
	$o2->new;
	is $dest, 2;
	h2o -classify=>'DestTest', -destroy=>sub{
			isa_ok shift, 'DestTest'; $dest++;
		}, {}; # note this object is immediately DESTROYed
	is $dest, 3;
	my $o3 = DestTest->new();
	is $dest, 3;
	$o3=undef;
	is $dest, 4;
	# This is here just for code coverage, the test for destructor errors being converted
	# to warnings that used to be here was buggy and moved to the author tests for now.
	my $od = h2o -destroy=>sub { die "You can safely ignore this warning during testing,\neven if it is followed by another \" at t/Util-H2O.t line ...\"." }, {}; ## no critic (RequireCarping)
}
{ # -destroy + -isa
	my $superdest = 0;
	{
		package DestIsaTest;  ## no critic (ProhibitMultiplePackages)
		sub DESTROY { $superdest++; return }
	}
	my $dest = 0;
	my $o1 = h2o -isa=>'DestIsaTest', -destroy=>sub{$dest++}, {};
	is $dest, 0;
	is $superdest, 0;
	$o1=undef;
	is $dest, 1;
	is $superdest, 0;
	my $dest2 = 0;
	h2o -isa=>'DestIsaTest', -classify=>'DestIsaH2O', { DESTROY=>sub{$dest2++} };
	is $dest2, 1;
	is $superdest, 0;
	{
		package DestIsaH2O2;  ## no critic (ProhibitMultiplePackages)
		use Util::H2O;
		h2o -isa=>'DestIsaTest', -classify, {
			DESTROY=>sub{ my $self=shift; $dest2++; $self->SUPER::DESTROY(@_) } };
	}
	is $dest2, 2;
	is $superdest, 1;
}

# DESTROY
{
	ok h2o -class=>'DestroyTest1', -meth, { DESTROY=>sub{} };
	ok h2o -clean=>0, -meth, { DESTROY=>sub{} };
	ok exception { h2o -class=>'DestroyTest2', -clean=>1, -meth, { DESTROY=>sub{} } };
	ok exception { h2o -class=>'DestroyTest3', -meth, { DESTROY=>'' } };
	ok exception { h2o -class=>'DestroyTest4', -meth, { DESTROY=>undef } };
	ok exception { h2o -class=>'DestroyTest5', { DESTROY=>sub{} } };
	ok exception { h2o -class=>'DestroyTest6', -meth, destroy=>sub{}, { DESTROY=>sub{} } };
	ok exception { h2o -clean=>0, -meth, { DESTROY=>'' } };
	ok exception { h2o -clean=>0, -meth, { DESTROY=>undef } };
	ok exception { h2o -clean=>0, { DESTROY=>sub{} } };
	ok exception { h2o -clean=>0, -meth, -destroy=>sub{}, { DESTROY=>sub{} } };
	ok exception { h2o -meth, { DESTROY=>sub{} } };
	ok exception { h2o { DESTROY=>sub{} } };
	ok exception { h2o { DESTROY=>undef } };
}

# plain AUTOLOAD
{
	my $o = h2o { AUTOLOAD => 123, baz => 789 }, 'abc';  ## no critic (ProhibitCommaSeparatedStatements)
	is $o->AUTOLOAD, 123;
	is $o->foo, 123;
	is $o->bar(456), 456;
	is $o->quz, 456;
	is $o->baz, 789;
	is $o->abc, undef;
	$o->abc('def');
	is $o->xyz, 456;
	is $o->abc, 'def';
	is $o->baz, 789;
	is $o->AUTOLOAD, 456;
}
# -meth with AUTOLOAD
{
	my @auto;
	my $o = h2o -meth, { AUTOLOAD => sub {
			our $AUTOLOAD;
			push @auto, $AUTOLOAD, [@_];
			return 'ijk';
		} }, 'quz';
	is $o->foo("bar"), 'ijk';
	is $o->bar(), 'ijk';
	is $o->quz("baz"), 'baz';
	is_deeply \@auto, [
		ref($o).'::foo', [ $o, "bar" ],
		ref($o).'::bar', [ $o ],
	] or diag explain \@auto;
	is $o->quz, "baz";
	is_deeply [keys %$o], ["quz"];
}

ok !grep { /redefined/i } warns {
	h2o { abc => "def" }, qw/ abc /;
	h2o {}, qw/ abc abc /;
};

SKIP: {
	skip "Tests only for old Perls", 4 if $] ge '5.008009';
	my @w = warns {
		my $o1 = h2o {};
		$o1->{bar} = 456;
		is_deeply [%$o1], [ bar=>456 ];
		my $o2 = h2o -ro, { foo=>123 };
		$o2->{foo} = 456;
		ok exception { $o2->foo(789) };
		is_deeply [%$o2], [ foo=>456 ];
	};
	is grep({ /\btoo old\b/i } @w), 2;
}

{ # -pass
	like blessed( h2o {} ), $PACKRE;
	like blessed( h2o -pass=>'undef', {} ), $PACKRE;
	# "undef"
	is h2o(-pass=>'undef', undef), undef;
	ok exception { h2o -pass=>'undef', [] };
	ok exception { h2o -pass=>'undef', "foo" };

	my $sref = \"foo";
	my $aref = [ { xyz=>'abc' } ];
	my $obj = bless {}, "SomeClass";

	# "ref"
	like blessed( h2o -pass=>'ref', {} ), $PACKRE;
	is h2o(-pass=>'ref', $sref), $sref;
	is h2o(-pass=>'ref', $obj), $obj;
	is 0+h2o(-recurse, -pass=>'ref', $aref), 0+$aref;
	ok !blessed($aref->[0]);
	is ref($aref->[0]), 'HASH';
	is h2o(-pass=>'ref', undef), undef;
	ok exception { h2o -pass=>'ref', "foo" };
	ok exception { h2o -pass=>'ref', 1234 };
	ok exception { h2o -pass=>'ref', -123 };
	ok exception { h2o -pass=>'ref', "-foobar" };

	# Note to self: I decided against implementing "any" because then
	# there is ambiguity when negative numbers or strings starting with
	# dashes look like options.
	ok exception { h2o -pass=>'any', {} };
}

ok exception { h2o() };
ok exception { h2o("blah") };
ok exception { h2o(undef) };
ok exception { h2o([]) };
ok exception { h2o(-meth,-recurse) };
ok exception { h2o(bless {}, "SomeClass") };
ok exception { h2o({DESTROY=>'foo'}) };
ok exception { h2o(-new, { new=>5 }) };
ok exception { h2o(-foobar) };
ok exception { h2o(-class) };
ok exception { h2o(-class=>'') };
ok exception { h2o(-class=>[]) };
ok exception { h2o(-classify) };
ok exception { h2o(-classify=>'') };
ok exception { h2o(-classify=>[]) };
ok exception { h2o(-destroy=>'') };
ok exception { h2o(-destroy=>undef) };
ok exception { h2o(-isa=>{}) };
ok exception { h2o -pass=>undef, {} };
ok exception { h2o -pass=>[], {} };
ok exception { h2o -pass=>"foo", {} };

diag "If all tests pass, you can ignore the \"this Perl is too old\" warnings"
	if $] lt '5.008009';

done_testing;

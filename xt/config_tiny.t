#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Util::H2O> used together with L<Config::Tiny>.

=head1 Author, Copyright, and License

Copyright (c) 2020-2021 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

## no critic (RequireTestLabels)

use Test::More tests => 15;
use File::Temp qw/tempfile/;
use Util::H2O 0.16;
use Config::Tiny 2.27;

my $confstr = <<'EOF';
hello=world

[foo]
bar=quz
EOF

my $expect = {
	_ => { hello=>"world" },
	foo => { bar=>"quz" },
};

my ($tfh, $tfn) = tempfile(UNLINK=>1);
print $tfh $confstr;
close $tfh;

my $destr_count = 0;
{
	my $cfg = Config::Tiny->read($tfn);
	isa_ok $cfg, 'Config::Tiny';
	is_deeply $cfg, $expect;
	my $cfg1 = $cfg;
	
	h2o -force, -recurse, -nolock, -destroy=>sub{$destr_count++}, $cfg;
	like ref($cfg), $Util::H2O::_PACKAGE_REGEX;  ## no critic (ProtectPrivateVars)
	is_deeply $cfg, $expect;
	is $cfg->_->hello, "world";
	is $cfg->foo->bar, "quz";
	my $cfg2 = $cfg;
	my $pkg = ref $cfg;
	
	$cfg = Config::Tiny->new($cfg);
	isa_ok $cfg, 'Config::Tiny';
	is_deeply $cfg, $expect;
	my $cfg3 = $cfg;
	
	ok $cfg1==$cfg2 && $cfg2==$cfg3;
	
	is $cfg->write_string, $confstr;
	
	{
		no strict 'refs';  ## no critic (ProhibitNoStrict)
		ok exists &{$pkg."::foo"}, $pkg."::foo still exists";
	}
	{
		my $config = h2o -nolock, -recurse, { abc => { def=>"ghi" } };
		my $ref = ref($config)."::abc";
		{
			no strict 'refs';  ## no critic (ProhibitNoStrict)
			ok exists(&$ref), "$ref exists";
		}
		$config = Config::Tiny->new({%$config});
		is $config->write_string, "[abc]\ndef=ghi\n";
		{
			no strict 'refs';  ## no critic (ProhibitNoStrict)
			ok !exists(&$ref), "$ref no longer exists";
		}
	}
}
is $destr_count, 0;

done_testing;


#!perl
package Util::H2O;
use warnings;
use strict;
use Exporter 'import';
use Carp;
use Symbol qw/delete_package/;

=head1 Name

Util::H2O - Hash to Object: turns hashrefs into objects with accessors for keys

=head1 Synopsis

 use Util::H2O;
 my $hash = h2o { foo => "bar", x => "y" }, qw/ more keys /;
 print $hash->foo, "\n";           # accessor
 $hash->x("z");                    # change value
 $hash->more("quz");               # additional keys
 
 my $struct = { hello => { perl => "world!" } };
 h2o -recurse, $struct;            # objectify nested hashrefs as well
 print $struct->hello->perl, "\n";
 
 my $obj = h2o -meth, {            # code references become methods
     what => "beans",
     cool => sub {
         my $self = shift;
         print $self->what, "\n";
     } };
 $obj->cool;                       # prints "beans"

=cut

our $VERSION = '0.01';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our @EXPORT = qw/ h2o /;  ## no critic (ProhibitAutomaticExportation)

=head1 Description

This module exports a single function by default.

=head2 C<h2o I<@opts>, I<$hashref>, I<@additional_keys>>

Turns hashrefs into objects, so that instead of C<< $hash->{key} >>
you can write C<< $hash->key >>, plus you get protection from typos.
Be aware that this I<does> modify the original hashref.

Nested hashes can be objectified as well if you supply the
C<-recurse> option as the first argument; additional keys apply to
the toplevel hash only.

If you supply the C<-meth> option, then any code references present
in the hash will become methods. Even when used together with
C<-recurse>, only code references in the toplevel hash are
methodified.

I<Note:> The hash may not contain a key named C<DESTROY>.

=cut

sub h2o {  ## no critic (RequireArgUnpacking)
	my ($recurse,$meth);
	while ( @_ && $_[0] && !ref$_[0] ) {
		if ($_[0] eq '-recurse') { $recurse = shift   }
		elsif ($_[0] eq '-meth') { $meth    = shift   }
		else { croak "unknown option to h2o: '$_[0]'" }
	}
	my $hash = shift;
	croak "h2o must be given a plain hashref" unless ref $hash eq 'HASH';
	croak "h2o hashref may not contain a key named DESTROY" if exists $hash->{DESTROY};
	if ($recurse) { ref eq 'HASH' and h2o(-recurse,$_) for values %$hash }
	my $pack = sprintf('Util::H2O::_%x', $hash+0);
	for my $k (@_, keys %$hash) {
		my $sub = $meth && ref $$hash{$k} eq 'CODE' ? $$hash{$k}
			: sub { my $self = shift; $self->{$k} = shift if @_; $self->{$k} };
		{ no strict 'refs'; *{"${pack}::$k"} = $sub }  ## no critic (ProhibitNoStrict)
	}
	my $sub = sub { delete_package($pack) };
	{ no strict 'refs'; *{$pack.'::DESTROY'} = $sub }  ## no critic (ProhibitNoStrict)
	return bless $hash, $pack;
}

1;
__END__

=head1 See Also

Inspired in part by C<lock_keys> from L<Hash::Util>.

Many, many other modules exist to simplify object creation in Perl.
This one is mine C<;-P>

For real OO work, I like L<Moo> and L<Type::Tiny>.

=head1 Author, Copyright, and License

Copyright (c) 2020 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

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

our $VERSION = '0.02';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our @EXPORT = qw/ h2o /;  ## no critic (ProhibitAutomaticExportation)

=head1 Description

This module allows you to turn hashrefs into objects, so that instead
of C<< $hash->{key} >> you can write C<< $hash->key >>, plus you get
protection from typos. In addition, options are provided that allow
you to whip up really simple classes.

This module exports a single function by default.

=head2 C<h2o I<@opts>, I<$hashref>, I<@additional_keys>>

=head3 C<@opts>

=over

=item C<-recurse>

Nested hashes are objectified as well. Note that none of the other
options will be applied to the nested hashes, including
C<@additional_keys>.

=item C<-meth>

Any code references present in the hash will become methods.

=item C<< -class => I<classname> >>

Specify the class name into which to bless the object (as opposed to
the default: a generated, unique package name in C<Util::H2O::>).

I<Warnings:> If that package already exists, this may step on its
toes! As opposed to the default behavior, the packages created with
this option won't be cleaned up, so if you generate many of them,
Perl's symbol table will fill up and use memory! Therefore, this
option is really only meant for quick prototyping and testing.

=back

=head3 C<$hashref>

You must supply a plain (unblessed) hash reference here. Be aware that
this function I<does> modify the original hashref(s) by blessing it.

I<Note:> The hash may not contain a key named C<DESTROY>, I<unless>
you've specified the C<-class> option.

=head3 C<@additional_keys>

Methods will be set up for these keys even if they do not exist in the hash.

=head3 Returns

The (now blessed) C<$hashref>.

=cut

sub h2o {  ## no critic (RequireArgUnpacking, ProhibitExcessComplexity)
	my ($recurse,$meth,$class);
	while ( @_ && $_[0] && !ref$_[0] ) {
		if ($_[0] eq '-recurse' ) { $recurse = shift   }
		elsif ($_[0] eq '-meth' ) { $meth    = shift   }
		elsif ($_[0] eq '-class') {
			$class = (shift, shift);
			croak "invalid -class option value"
				if !defined $class || ref $class || !length $class;
		}
		else { croak "unknown option to h2o: '$_[0]'" }
	}
	my $hash = shift;
	croak "h2o must be given a plain hashref" unless ref $hash eq 'HASH';
	croak "h2o hashref may not contain a key named DESTROY"
		if !defined $class && exists $hash->{DESTROY};
	if ($recurse) { ref eq 'HASH' and h2o(-recurse,$_) for values %$hash }
	my $pack = defined $class ? $class : sprintf('Util::H2O::_%x', $hash+0);
	for my $k (@_, keys %$hash) {
		my $sub = $meth && ref $$hash{$k} eq 'CODE' ? $$hash{$k}
			: sub { my $self = shift; $self->{$k} = shift if @_; $self->{$k} };
		{ no strict 'refs'; *{"${pack}::$k"} = $sub }  ## no critic (ProhibitNoStrict)
	}
	if ( !defined $class ) {
		my $sub = sub { delete_package($pack) };
		{ no strict 'refs'; *{$pack.'::DESTROY'} = $sub }  ## no critic (ProhibitNoStrict)
	}
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

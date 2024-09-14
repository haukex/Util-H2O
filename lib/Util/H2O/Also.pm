#!perl
package Util::H2O::Also;
use warnings;
use strict;

=head1 Name

Util::H2O::Also - Alternative single-class version of Util::H2O (but slower)

=head1 Synopsis

 TODO

=cut

our $VERSION = '0.26';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

use Carp ();
use Hash::Util ();
use Scalar::Util ();

sub new {
    my $class = shift;
    # allow $object->new to access hash key 'new'
    if (Scalar::Util::blessed($class) && UNIVERSAL::isa($class, __PACKAGE__))  ## no critic (ProhibitUniversalIsa)
        { our $AUTOLOAD = 'new'; goto &AUTOLOAD }
    my $hashref = shift;
    bless $hashref, $class;
    #TODO: Hash::Util::lock_hashref($hashref);
    return $hashref;
}

sub AUTOLOAD {  ## no critic (ProhibitAutoloading)
    our $AUTOLOAD;
    # allow $object->AUTOLOAD to access hash key 'AUTOLOAD'
    $AUTOLOAD = 'AUTOLOAD' if !defined $AUTOLOAD;
    ( my $key = $AUTOLOAD ) =~ s/.*:://;
    undef $AUTOLOAD;  # reset this so $object->AUTOLOAD still works
    my $self = shift;
    return if $key eq 'DESTROY' && !exists $self->{$key};
    Carp::croak("Can't locate object method \"$key\" via package \"".ref($self)."\"") unless exists $self->{$key};
    $self->{$key} = shift if @_;
    return $self->{$key};
}

# Override UNIVERSAL methods:
sub DOES     { our $AUTOLOAD='DOES';     goto &AUTOLOAD }
sub VERSION  { our $AUTOLOAD='VERSION';  goto &AUTOLOAD }

# But don't override these so as to not break common expectations of Perl's objects:
#sub can     { our $AUTOLOAD='can';      goto &AUTOLOAD }
#sub isa     { our $AUTOLOAD='isa';      goto &AUTOLOAD }

# Perl doesn't autoload these either:
#TODO: this prevents `use Util::H2O::Also;` sub import   { our $AUTOLOAD='import';   goto &AUTOLOAD }
sub unimport { our $AUTOLOAD='unimport'; goto &AUTOLOAD }

1;
__END__

=head1 Author, Copyright, and License

Copyright (c) 2024 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

#!perl
package Util::H2O::Also;
use warnings;
use strict;

=head1 Name

Util::H2O::Also - Alternative single-class version of Util::H2O (but slower)

=head1 Experimental

B<This is an experimental module.>
B<As long as this "experimental" notice is present, the API may still change significantly.>

=head1 Synopsis

 use Util::H2O::Also;
 
 my $hash = Util::H2O::Also->new( { foo => "bar", x => "y" } );
 print $hash->foo, "\n";           # accessor
 $hash->x("z");                    # change value
 
 # subclassing
 {
     package MyClass;
     use parent 'Util::H2O::Also';
     sub cool {
         my $self = shift;
         print $self->what, "\n";
     }
 }
 my $obj = MyClass->new( { what=>"beans" } );
 $obj->cool;                       # prints "beans"

=cut

our $VERSION = '0.26';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

=head1 Description

This B<experimental> module was heavily inspired by L<Object::Accessor|Object::Accessor>.
While L<Util::H2O|Util::H2O> generates a new package for each hash wrapped in an object,
this module uses a single package and C<AUTOLOAD>.

The advantages are that you get less packages (which may consume a large amount of memory
if you're creating a lot of C<h2o> objects), and it's very easy to subclass this module to
create multiple objects with the same custom package name. Another minor advantage is that
if the underlying hash is modified, the corresponding accessors for those hash keys will
seem to "appear magically".

The major disadvantage appears to be speed:
testing shows that even a simple attribute access is six times slower!

Also, I have so far only implemented some very basic options (see below), so this module
doesn't (yet) provide the richness of options that L<Util::H2O|Util::H2O> does.
Instead, for now this class is just a testbed to compare the two implementations.
Feedback is welcome!

=head1 C<< Util::H2O::Also->new(I<@opts>, I<$hashref>) >>

=head2 C<@opts>

=head3 C<-ro>

Use L<Hash::Util|Hash::Util>'s C<lock_hashref> to lock the entire hash,
essentially making it immutable.

=head3 C<-nolock>

Don't use L<Hash::Util|Hash::Util>'s C<lock_ref_keys> to lock the keys of the hash.

=head2 C<$hashref>

The hash reference to wrap. Will be locked (or not) according to the C<-nolock>/C<-ro> options.

=cut

use Carp ();
use Hash::Util ();
use Scalar::Util ();

sub new {  ## no critic (RequireArgUnpacking)
    # allow $object->new to access hash key 'new'
    if ( @_ && Scalar::Util::blessed($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__) )  ## no critic (ProhibitUniversalIsa)
        { our $AUTOLOAD = 'new'; goto &AUTOLOAD }
    my $class = shift;
    my ($lock,$ro) = (1);
    while ( @_ && $_[0] && !ref $_[0] && $_[0]=~/^-/ ) {
        if    ($_[0] eq '-nolock'){ $lock = 0; shift }
		elsif ($_[0] eq '-ro'   ) { $ro      = shift }
		else { Carp::croak("unknown option to $class->new(): '$_[0]'") }
    }
    Carp::croak("can't use -nolock and -ro together") if !$lock && $ro;
    my $hashref = shift;
    Carp::croak("$class->new() only accepts plain hashrefs") unless ref $hashref eq 'HASH';
    bless $hashref, $class;
    if ($ro) { Hash::Util::lock_hashref($hashref) }
    elsif ($lock) { Hash::Util::lock_ref_keys($hashref) }
    return $hashref;
}

sub AUTOLOAD {  ## no critic (ProhibitAutoloading, RequireArgUnpacking)
    our $AUTOLOAD;
    # allow $object->AUTOLOAD to access hash key 'AUTOLOAD'
    $AUTOLOAD = 'AUTOLOAD' if !defined $AUTOLOAD;
    ( my $key = $AUTOLOAD ) =~ s/.*:://;
    undef $AUTOLOAD;  # reset this so $object->AUTOLOAD still works
    Carp::confess("Internal error: AUTOLOAD key='$key' called on "
        .(defined $_[0] ? $_[0] : 'undef'))
        unless Scalar::Util::blessed($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__);  ## no critic (ProhibitUniversalIsa)
    my $self = shift;
    return if $key eq 'DESTROY' && !exists $self->{$key};
    Carp::croak("Can't locate object method \"$key\" via package \"".ref($self)."\"")
        unless exists $self->{$key};
    $self->{$key} = shift if @_;
    return $self->{$key};
}

# Override UNIVERSAL methods:
sub DOES     { our $AUTOLOAD='DOES';     goto &AUTOLOAD }
sub VERSION  { our $AUTOLOAD='VERSION';  goto &AUTOLOAD }

# Perl doesn't autoload these either
# (we still need to allow calling them regularly, like with `use Util::H2O::Also`)
sub import {  ## no critic (RequireArgUnpacking)
    if ( @_ && Scalar::Util::blessed($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__) )  ## no critic (ProhibitUniversalIsa)
        { our $AUTOLOAD='import'; goto &AUTOLOAD }
}
sub unimport {  ## no critic (RequireArgUnpacking)
    if ( @_ && Scalar::Util::blessed($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__) )  ## no critic (ProhibitUniversalIsa)
        { our $AUTOLOAD='unimport'; goto &AUTOLOAD }
}

# But don't override ->isa so as to not break common expectations of Perl's objects:
#sub isa     { our $AUTOLOAD='isa';      goto &AUTOLOAD }

# And provide a custom ->can that checks the hash:
sub can {
    my ($self, $method) = @_;
    return undef unless $method;  ## no critic (ProhibitExplicitReturnUndef)
    # the following are the only two we don't override
    return $self->UNIVERSAL::can($method) if $method eq 'isa' || $method eq 'can';
    # for these, only return their code refs if they are also keys in the hash
    if ( $method eq 'import' || $method eq 'unimport' || $method eq 'DOES'
            || $method eq 'AUTOLOAD' || $method eq 'VERSION' || $method eq 'new' ) {
        return exists $self->{$method} ? $self->UNIVERSAL::can($method) : undef;
    }
    # otherwise, if we've been subclassed, the user may have implemented the method
    my $code = $self->UNIVERSAL::can($method);
    return $code if defined $code;
    # and finally, if the key is in the hash, return the accessor
    return exists $self->{$method} ? sub { our $AUTOLOAD=$method; goto &AUTOLOAD } : undef;
}

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

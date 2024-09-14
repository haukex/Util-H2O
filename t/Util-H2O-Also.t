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

use Test::More tests=>146;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)

## no critic (RequireTestLabels)

diag "This is Perl $] at $^X on $^O";
BEGIN { require_ok 'Util::H2O::Also' }
is $Util::H2O::Also::VERSION, '0.26';

# basic tests
{
    my $o = Util::H2O::Also->new({foo=>'bar'});
    isa_ok $o, 'Util::H2O::Also';
    # basic read/write
    is $o->foo, 'bar';
    is $o->foo('quz'), 'quz';
    is $o->foo, 'quz';
    # unknown key
    ok exception { $o->bar };
    ok exception { $o->{bar} };
    ok !exists $o->{bar};
    # can
    is ref $o->can('foo'), 'CODE';
    is $o->can('foo')->($o), 'quz';
    is $o->can('bar'), undef;
    is ref $o->can('can'), 'CODE';
    is ref $o->can('can')->($o, 'isa'), 'CODE';
    is ref $o->can('isa'), 'CODE';
    ok $o->can('isa')->($o, 'Util::H2O::Also');
    ok !$o->can('isa')->($o, 'Test1');
    is $o->can('new'), undef;
    is $o->can('AUTOLOAD'), undef;
    is $o->can('DOES'), undef;
    is $o->can('VERSION'), undef;
    is $o->can('import'), undef;
    is $o->can('unimport'), undef;
    is $o->can('DESTROY'), undef;
}
# test overridden methods
{
    my $o = Util::H2O::Also->new({ new=>'n', AUTOLOAD=>'a', DOES=>'d', VERSION=>'v', import=>'i',
        unimport=>'u', DESTROY=>'D' });
    isa_ok $o, 'Util::H2O::Also';
    is $o->new, 'n';
    is $o->AUTOLOAD, 'a';
    is $o->DOES, 'd';
    is $o->VERSION, 'v';
    is $o->import, 'i';
    is $o->unimport, 'u';
    # can
    is $o->can('foo'), undef;
    is $o->can('bar'), undef;
    is ref $o->can('can'), 'CODE';
    is ref $o->can('isa'), 'CODE';
    is ref $o->can('new'), 'CODE';
    is $o->can('new')->($o), 'n';
    is ref $o->can('AUTOLOAD'), 'CODE';
    is $o->can('AUTOLOAD')->($o), 'a';
    is ref $o->can('DOES'), 'CODE';
    is $o->can('DOES')->($o), 'd';
    is ref $o->can('VERSION'), 'CODE';
    is $o->can('VERSION')->($o), 'v';
    is ref $o->can('import'), 'CODE';
    is $o->can('import')->($o), 'i';
    is ref $o->can('unimport'), 'CODE';
    is $o->can('unimport')->($o), 'u';
    is ref $o->can('DESTROY'), 'CODE';
    is $o->can('DESTROY')->($o), 'D';
}
# test subclassing
{
    package Test1;
    use parent 'Util::H2O::Also';
    sub quz { return 'Quz' }
}
{
    # basic subclassing: one attribute from hash and one method from class
    my $o = Test1->new({foo=>'bar'});
    isa_ok $o, 'Util::H2O::Also';
    isa_ok $o, 'Test1';
    is $o->foo, 'bar';
    is $o->quz, 'Quz';
    # can
    is ref $o->can('foo'), 'CODE';
    is $o->can('foo')->($o), 'bar';
    is $o->can('bar'), undef;
    is ref $o->can('quz'), 'CODE';
    is $o->can('quz')->(), 'Quz';
    is ref $o->can('can'), 'CODE';
    is ref $o->can('isa'), 'CODE';
    is $o->can('new'), undef;
    is $o->can('AUTOLOAD'), undef;
    is $o->can('DOES'), undef;
    is $o->can('VERSION'), undef;
    is $o->can('import'), undef;
    is $o->can('unimport'), undef;
    is $o->can('DESTROY'), undef;
}
{
    # the method from the class overrides the attribute from the hash
    my $o = Test1->new({quz=>'Hello'});
    isa_ok $o, 'Util::H2O::Also';
    isa_ok $o, 'Test1';
    is $o->quz, 'Quz';
    # can
    is $o->can('foo'), undef;
    is $o->can('bar'), undef;
    is ref $o->can('quz'), 'CODE';
    is $o->can('quz')->(), 'Quz';
    is ref $o->can('can'), 'CODE';
    is ref $o->can('isa'), 'CODE';
    is $o->can('new'), undef;
    is $o->can('AUTOLOAD'), undef;
    is $o->can('DOES'), undef;
    is $o->can('VERSION'), undef;
    is $o->can('import'), undef;
    is $o->can('unimport'), undef;
    is $o->can('DESTROY'), undef;
}
{
    # overridden method still work as attributes
    my $o = Test1->new({ new=>'n', AUTOLOAD=>'a', DOES=>'d', VERSION=>'v', import=>'i',
        unimport=>'u', DESTROY=>'D' });
    isa_ok $o, 'Util::H2O::Also';
    isa_ok $o, 'Test1';
    is $o->quz, 'Quz';
    is $o->new, 'n';
    is $o->AUTOLOAD, 'a';
    is $o->DOES, 'd';
    is $o->VERSION, 'v';
    is $o->import, 'i';
    is $o->unimport, 'u';
    # can
    is $o->can('foo'), undef;
    is $o->can('bar'), undef;
    is ref $o->can('quz'), 'CODE';
    is $o->can('quz')->(), 'Quz';
    is ref $o->can('can'), 'CODE';
    is ref $o->can('isa'), 'CODE';
    is ref $o->can('new'), 'CODE';
    is $o->can('new')->($o), 'n';
    is ref $o->can('AUTOLOAD'), 'CODE';
    is $o->can('AUTOLOAD')->($o), 'a';
    is ref $o->can('DOES'), 'CODE';
    is $o->can('DOES')->($o), 'd';
    is ref $o->can('VERSION'), 'CODE';
    is $o->can('VERSION')->($o), 'v';
    is ref $o->can('import'), 'CODE';
    is $o->can('import')->($o), 'i';
    is ref $o->can('unimport'), 'CODE';
    is $o->can('unimport')->($o), 'u';
    is ref $o->can('DESTROY'), 'CODE';
    is $o->can('DESTROY')->($o), 'D';
}

# default: lock keys
{
    my $h = { hello=>'world' };
    my $o = Util::H2O::Also->new($h);
    ok exception { $h->{world} = 'perl' };
    is ref $o->can('hello'), 'CODE';
    is $o->can('hello')->($o), 'world';
    is $o->can('world'), undef;
}
# lock entire hash
{
    my $h = { hello=>'world' };
    my $o = Util::H2O::Also->new(-ro, $h);
    ok exception { $h->{world} = 'perl' };
    ok exception { delete $h->{hello} };
    ok exception { $h->{hello} = 'foo' };
    # can
    is ref $o->can('hello'), 'CODE';
    is $o->can('hello')->($o), 'world';
    is $o->can('world'), undef;
}
# nolock
{
    my $h = { hello=>'world' };
    my $o = Util::H2O::Also->new(-nolock, $h);
    # modifying the hash makes the accessor work
    $h->{world} = 'perl';
    is $h->world, 'perl';
    # but calling an accessor for a nonexistent hash key still doesn't work (TODO Later: should it?)
    ok exception { $h->err };
    # can
    is ref $o->can('hello'), 'CODE';
    is $o->can('hello')->($o), 'world';
    is ref $o->can('world'), 'CODE';
    is $o->can('world')->($o), 'perl';
}

# exceptions
{
    my $dummy = bless {}, 'Dummy';
    ok exception { Util::H2O::Also->new() };
    ok exception { Util::H2O::Also->new($dummy) };
    ok exception { Util::H2O::Also->new('') };
    ok exception { Util::H2O::Also->new('bad') };
    ok exception { Util::H2O::Also->new(-bad) };
    ok exception { Util::H2O::Also->new(-ro, -nolock, {}) };
}

# unusual things that shouldn't happen in normal code (mostly for coverage)
{
    is( Util::H2O::Also->new({})->can(), undef );
    my $dummy = bless {}, 'Dummy';
    ok( !Util::H2O::Also::import() );
    ok( !Util::H2O::Also::import({}) );
    ok( !Util::H2O::Also::import($dummy) );
    ok( !Util::H2O::Also::unimport() );
    ok( !Util::H2O::Also::unimport({}) );
    ok( !Util::H2O::Also::unimport($dummy) );
    ok exception { Util::H2O::Also::AUTOLOAD() };
    ok exception { Util::H2O::Also::AUTOLOAD({}) };
    ok exception { Util::H2O::Also::AUTOLOAD($dummy) };
    ok exception { Util::H2O::Also::new() };
    ok exception { Util::H2O::Also::new($dummy) };
}

done_testing;

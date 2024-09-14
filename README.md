Util::H2O
=========

This is the distribution of the Perl module
[`Util::H2O`](https://metacpan.org/pod/Util::H2O).

It is a Perl extension for turning hashrefs into objects with accessors for keys.

Please see the module's documentation (POD) for details (try the command
`perldoc lib/Util/H2O.pm`) and the file `Changes` for version information.

[![GitHub Actions Basic Tests Status](https://github.com/haukex/Util-H2O/actions/workflows/basic-tests.yml/badge.svg)](https://github.com/haukex/Util-H2O/actions/workflows/basic-tests.yml)
[![GitHub Actions Full Tests Status](https://github.com/haukex/Util-H2O/actions/workflows/full-tests.yml/badge.svg)](https://github.com/haukex/Util-H2O/actions/workflows/full-tests.yml)
[![Kwalitee Score](https://cpants.cpanauthors.org/dist/Util-H2O.svg)](https://cpants.cpanauthors.org/dist/Util-H2O)
[![CPAN Testers](https://haukex.github.io/my-badges/Util-H2O.svg)](http://matrix.cpantesters.org/?dist=Util-H2O)

Installation
------------

To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`, or `gmake`
instead of `make`.

Dependencies
------------

Requirements: Perl v5.8.9 or higher (a more current version is *strongly*
recommended) and several of its core modules; users of older Perls may need
to upgrade some core modules.

The full list of required modules can be found in the file `Makefile.PL`.
This module should work on any platform supported by these modules.

Author, Copyright and License
-----------------------------

Copyright (c) 2020-2024 Hauke Daempfling <haukex@zero-g.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the Perl Artistic License,
which should have been distributed with your copy of Perl.
Try the command `perldoc perlartistic` or see
<http://perldoc.perl.org/perlartistic.html>


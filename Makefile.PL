#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;
WriteMakefile(
	NAME             => 'Util::H2O',
	AUTHOR           => 'Hauke D <haukex@zero-g.net>',
	LICENSE          => 'perl_5',
	VERSION_FROM     => 'lib/Util/H2O.pm',
	ABSTRACT_FROM    => 'lib/Util/H2O.pm',
	MIN_PERL_VERSION => '5.8.9',
	META_MERGE => {
		'meta-spec' => { version => 2 },
		provides => {
			'Util::H2O' => {
				file => 'lib/Util/H2O.pm',
				version => '0.26',
			},
			'Util::H2O::Also' => {
				file => 'lib/Util/H2O/Also.pm',
				version => '0.26',
			},
		},
		resources => {
			homepage => 'https://github.com/haukex/Util-H2O',
			repository => {
				type => 'git',
				url  => 'https://github.com/haukex/Util-H2O.git',
				web  => 'https://github.com/haukex/Util-H2O',
			},
			bugtracker => {
				web  => 'https://github.com/haukex/Util-H2O/issues',
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM => {
		'Carp'                   => 0,
		'Exporter'               => '5.58',
		'Symbol'                 => 0,
		'Hash::Util'             => '0.06',
	},
	TEST_REQUIRES => {
		'Test::More'             => '1.302096',
		'Scalar::Util'           => 0,
	},
);
sub MY::postamble {
	return <<'MAKE_FRAG';
.PHONY: authorcover
authorcover: test
	cpanm Devel::Cover
	cover -test
MAKE_FRAG
}

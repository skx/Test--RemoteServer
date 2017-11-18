# $Id$

use strict;
use lib './t/lib';
use ExtUtils::MakeMaker;

my %prereq_pm = ( 'Test::Builder' => 0,
                  'Net::DNS'      => 0,
                );

my %test_pm = (
               # solely for the test-suite.
               'Test::More'       => 0,
               'Test::Strict'     => 0,
               'Test::Pod'        => 0,
               'Test::NoTabs'     => 0,
              );

WriteMakefile(
    NAME         => 'Test::RemoteServer',
    VERSION_FROM => 'lib/Test/RemoteServer.pm',
    PREREQ_PM    => \%prereq_pm,
    TEST_REQUIRES => \%test_pm,
    ABSTRACT     => 'Test routines for remote servers.',
    AUTHOR       => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE      => 'perl',

    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://github.com/skx/Test-RemoteServer/',
            bugtracker => 'https://github.com/skx/Test-RemoteServer/issues',
            repository => 'https://github.com/skx/Test-RemoteServer.git',

                     },
                  },
             );


package MY;

sub metafile {
        my $self    = shift;
        my $meta    = $self->SUPER::metafile_target(@_);
        my ($extra) = $self->echo('license: perl_5', 'MYMETA.yml', 1);
        return "$meta\t$extra\n";
}

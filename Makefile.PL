# $Id$

use strict;
use lib './t/lib';
use ExtUtils::MakeMaker;

my %prereq_pm = ( 'Test::Builder' => undef,
                  'Test::More'    => undef,
                  'Net::DNS'      => undef,
                );

WriteMakefile(
    NAME         => 'Test::RemoteServer',
    VERSION_FROM => 'lib/Test/RemoteServer.pm',
    PREREQ_PM    => \%prereq_pm,
    ABSTRACT     => 'Test routines for remote servers.',
    AUTHOR       => 'Steve Kemp <steve@steve.org.uk>',


    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://github.com/skx/Test-RemoteServer/',
            bugtracker => 'https://github.com/skx/Test-RemoteServer/issues',
            repository => 'https://github.com/skx/Test-RemoteServer.git',

                     },
                  },
             );


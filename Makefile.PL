# $Id$

use strict;
use lib './t/lib';
use ExtUtils::MakeMaker;

my %prereq_pm = ( 'Test::Builder' => undef,
                  'Test::More'    => undef,
                  'Net::DNS'      => undef,
                );

WriteMakefile( NAME         => 'Test::RemoteServer',
               VERSION_FROM => 'lib/Test/RemoteServer.pm',
               PREREQ_PM    => \%prereq_pm,
               ABSTRACT     => 'Test routines for remote servers.',
               AUTHOR       => 'Steve Kemp <steve@steve.org.uk>',
             );


package MY;
use strict;

sub postamble
{
    return <<'MAKE_TEXT';
prepare_dist ::	metafile manifest dist
	$(NOECHO) $(NOOP)
MAKE_TEXT
}

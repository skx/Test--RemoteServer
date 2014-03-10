#!/usr/bin/perl -Ilib/
#
#  Simple example test which connects to various hosts and tests
# them.
#
# Steve
# --
#

use strict;
use warnings;

use Test::More;
use Test::RemoteServer;

#
#  Some pre-test information.
#
print <<EOF;
Running Test::RemoteServer version - $Test::RemoteServer::VERSION
Timeouts are set to $Test::RemoteServer::TIMEOUT seconds

EOF



## testing ping responses
ping_ok( "localhost", "Localhost is dead?" );
ping6_ok( "localhost", "Localhost is dead?" );


## There should be a HTTP server
socket_open( "localhost", 80, "The webserver is dead!" );


## FTP shouldn't be running
socket_closed( "localhost", 21, "FTP should be disabled!" );


## Our domain should resolve
resolves( "steve.org.uk", "Our domain is unreachable!" );


## Test OpenSSH is secure.
ssh_auth_disabled( "planet.debian-administration.org:2222",
                   "password", "Password auth should be disabled" );
ssh_auth_enabled( "planet.debian-administration.org:2222",
                  "publickey", "Key auth is missing" );


## All done.
done_testing();

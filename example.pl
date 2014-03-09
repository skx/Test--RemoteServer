#!/usr/bin/perl -Ilib/


use strict;
use warnings;

use Test::More         tests => 5;
use Test::RemoteServer;

print "Running with $Test::RemoteServer::VERSION\n";

## testing ping responses
ping_ok("localhost", "Localhost is dead?" );
ping6_ok("localhost", "Localhost is dead?" );

## There should be a HTTP server
socket_open( "localhost", 80, "The webserver is dead!" );

## Our domain shoudl resolve
resolves( "example.com", "Our domain is unreachable!" );

## Test OpenSSH is secure.
ssh_auth_disabled( "planet.debian-administration.org:2222", "password",
                   "Password auth should be disabled");

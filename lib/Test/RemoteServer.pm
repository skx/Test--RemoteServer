
=head1 NAME

Test::RemoteServer - Test routines for remote servers.

=cut


=head1 SYNOPSIS

This module allows you to carry out basic tests against remote servers,
and the following example should make usage clear:

=for example begin

   use Test::More         tests => 5;
   use Test::RemoteServer;

   ## testing ping responses
   ping_ok("localhost", "Localhost is dead?" );
   ping6_ok("localhost", "Localhost is dead?" );

   ## There should be a HTTP server
   socket_open( "localhost", 80, "The webserver is dead!" );

   ## Our domain should resolve
   resolve( "example.com", "Our domain is unreachable!" );

   ## We don't want plaintext-password authentication.
   ssh_auth_disabled( "host.example.com:2222", "password",
                     "Password auth should be disabled");

=for example end

=cut


=head1 DESCRIPTION

C<Test::RemoteServer> allows you to use the C<Test::More> interface
to carry out basic health-checks against remote systems.

Currently the tests are only those that can be carried out without
any authentication, or faking of source-address.

It would be interesting to be able to test ACLs such that a particular
source address were able to connect to a host, but another was not.

(i.e. To test that a firewall is adequately protecting access by
source-IP).  However this kind of source-IP manipulation is not
generally portable, and has to be ruled out on that basis.

=cut


=head1 TIMEOUTS

All the test-methods are carried out against remote hosts which might
be slow, or even unreachable.  On that basis the tests are wrapped
with timeouts.

If you wish to change the default timeout, which is five seconds, please
set the timeout value B<prior> to invoking any tests:

=for example begin

     use Test::More         tests => 5;
     use Test::RemoteServer;

     #
     # Change each timeout to 20 seconds, from the default of 5.
     #
     $Test::RemoteServer::TIMEOUT = 20;


=for example end

=cut


=head1 USEFUL COMPANION MODULES

If your tests are only to be carried out on the localhost you might
enjoy the L<Test::Server> module.

If you wish to perform more complex DNS tests you should investigate
the L<Test::DNS> module.

Finally there is the L<Test::Varnish> which will examine the response
of a remote HTTP-server and determine whether Varnish is being used.

=cut


=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut


=head1 METHODS

Now follows method-documentation

=cut


use warnings;
use strict;


package Test::RemoteServer;


use File::Temp qw! tempfile !;
use IO::Socket::INET;
use Net::DNS;
use Test::Builder;

use base "Exporter";

our @EXPORT =
  qw( ping_ok ping6_ok resolves ssh_auth_enabled ssh_auth_disabled socket_open socket_closed );
our $VERSION = '0.5';


#
# Global timeout value
#
our $TIMEOUT = 5;


#
#  Helper
#
my $Test = Test::Builder->new;



=head2 ping_ok

Test that a ping succeeds against the named host, by executing the system's
C<ping> binary.

=cut

sub ping_ok ($$)
{
    my $HOST        = shift;
    my $description = shift;

    my $ok = 0;

    if ( system("ping -w1 -W1 -c 1 $HOST >/dev/null 2>/dev/null") == 0 )
    {
        $ok = 1;
    }

    $Test->ok( $ok, $description ) ||
      $Test->diag("Host $HOST down");

    return $ok;
}


=head2 ping6_ok

Test that a ping succeeds against the named host, by executing the system's
C<ping6> binary.

=cut

sub ping6_ok ($$)
{
    my $HOST        = shift;
    my $description = shift;

    my $ok = 0;

    if ( system("ping6 -W1 -w1 -c 1 $HOST >/dev/null 2>/dev/null") == 0 )
    {
        $ok = 1;
    }

    $Test->ok( $ok, $description ) ||
      $Test->diag("Host $HOST down");

    return $ok;
}


=head2 resolves

Test that a DNS request returns I<something>.

Because this method doesn't test the actual nature of the resolved result
it might be less useful than the L<Test::DNS> module, however it is a good
starting point.

Test the authors domain exists:

=for example begin

   ## Our domain should resolve
   resolves( "steve.org.uk", "Our domain is unreachable!" );

=for example end

=cut

sub resolves($$)
{
    my $HOST        = shift;
    my $description = shift;

    my $ok = 0;

    eval {
        local $SIG{ ALRM } = sub {die "alarm\n"};
        alarm($Test::RemoteServer::TIMEOUT);

        #
        #  Create a resolver object, and fire a query against it.
        #
        my $res   = Net::DNS::Resolver->new;
        my $query = $res->search($HOST);

        #
        #  If that didn't fail then we will bump the OK-count for each
        # result.  (Since we don't care about NS, A, MX, & etc.)
        #
        if ($query)
        {
            foreach my $rr ( $query->answer )
            {
                $ok += 1;
            }
        }
    };

    $Test->ok( $ok, $description ) ||
      $Test->diag("Failed to resolve $HOST");

    return $ok;
}



=head2 socket_open

This method ensures that a socket connection may be established to the
remote host/port pair.

For example if you have a webserver you should expect it to be running:

=for example begin

  socket_open( "www.example.com", 80, "HTTP should be enabled!" );

=for example end

=cut

sub socket_open($$$)
{
    my $HOST        = shift;
    my $PORT        = shift;
    my $description = shift;

    my $ok = 0;

    eval {
        local $SIG{ ALRM } = sub {die "alarm\n"};
        alarm($Test::RemoteServer::TIMEOUT);

        my $sock = IO::Socket::INET->new( PeerAddr => $HOST,
                                          PeerPort => $PORT,
                                          Proto    => 'tcp'
                                        );
        $ok = 1 if ( $sock->connected() );
    };


    $Test->ok( $ok, $description ) ||
      $Test->diag("Connection failed to $HOST:$PORT");

    return $ok;
}


=head2 socket_closed

This method ensures that a socket connection cannot be established to the
remote host/port pair.

For example if you believe that FTP is insecure you can ensure it isn't
present via:

=for example begin

  socket_closed( "localhost", 21, "FTP should be disabled!" );

=for example end

=cut

sub socket_closed($$$)
{
    my $HOST        = shift;
    my $PORT        = shift;
    my $description = shift;

    my $ok = 1;

    eval {
        local $SIG{ ALRM } = sub {die "alarm\n"};
        alarm($Test::RemoteServer::TIMEOUT);

        my $sock = IO::Socket::INET->new( PeerAddr => $HOST,
                                          PeerPort => $PORT,
                                          Proto    => 'tcp'
                                        );
        $ok = 0 if ( $sock->connected() );
    };

    $Test->ok( $ok, $description ) ||
      $Test->diag("Connection succeeded to $HOST:$PORT");

    return $ok;
}


=head2 ssh_auth_enabled

Ensure that the given SSH authentication-type is available.  For example
you might want to test that public-key authentication is supported:

=for example begin

  ssh_auth_enabled( "test.example.com:2222", "publickey",
                   "Key auth is missing");

=for example end

=cut

sub ssh_auth_enabled($$$)
{
    my $HOST        = shift;
    my $type        = shift;
    my $description = shift;

    my $ok = 0;


    my @valid = _get_ssh_auth_types($HOST);
    foreach my $advertised (@valid)
    {
        $ok = 1 if ( $advertised eq $type );
    }

    $Test->ok( $ok, $description ) ||
      $Test->diag(
        "$type not seen as a valid authentication option $HOST - $description");

    return $ok;
}



=head2 ssh_auth_disabled

Ensure that the given SSH authentication-type is disabled.  For example
you might want to test that password authentication is disabled:

=for example begin

  ssh_auth_disabled( "test.example.com:2222", "password",
                     "Dictionary attacks are possible");

=for example end

=cut

sub ssh_auth_disabled($$$)
{
    my $HOST        = shift;
    my $type        = shift;
    my $description = shift;

    my $ok = 1;


    my @valid = _get_ssh_auth_types($HOST);
    foreach my $advertised (@valid)
    {
        $ok = 0 if ( $advertised eq $type );
    }

    $Test->ok( $ok, $description ) ||
      $Test->diag(
            "$type was accepted as a valid authentication type - $description");

    return $ok;
}



=begin doc

Get the remote SSH authentication types.

=end doc

=cut

sub _get_ssh_auth_types
{
    my ($host) = (@_);

    my $port = 22;
    if ( $host =~ /^(.*):([0-9]+)$/ )
    {
        $host = $1;
        $port = $2;
    }
    my @types;

    #
    # Create a temporary file
    #
    my ( $fh, $tmp ) = tempfile();

    eval {
        local $SIG{ ALRM } = sub {die "alarm\n"};
        alarm($Test::RemoteServer::TIMEOUT);

        #
        # Connect to the remote host.
        #
        system(
              "ssh -o PreferredAuthentications=none -p $port $host 2>$tmp >&2");

        #
        #  Now look for the output
        #
        open( my $handle, "<", $tmp ) or
          die "Failed to open tmp file $!";

        while ( my $line = <$handle> )
        {
            if ( $line =~ /\(([^(]+)\)/i )
            {
                my $options = $1;
                @types = split( /,/, $options );
            }
        }
        close($handle);
    };

    unlink($tmp) if ( -e $tmp );

    return (@types);
}


1;

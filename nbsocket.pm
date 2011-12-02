#!/usr/bin/perl -w

#
# Bad Boren!  Should use Handle for unique sockets! :)
#

package NBSocket;

use Carp;
use Socket;
use IO::Handle;
#use Errno qw(:POSIX);
use Fcntl;  
no strict;

my $socknum = 0;

sub new {
  my $class = shift;
  my %params = @_;

  my $self = {};
  bless($self, $class);

  $self->{'Delayed'} = "No";

  my ($remote,$port, $proto, $iaddr, $paddr, $proto, $line, $oselected);
  $remote = $params{'-Remote'};
  $port = $params{'-Port'};
  $proto = $params{'-Proto'} ? $params{'-Proto'} : 'tcp';
  $blocking = $params{'-Blocking'} ? $params{'-Blocking'} : '0';
  $socket = $params{'-Socket'};
  
  if ($socket eq undef)
    {
      $self->{'socket'} = $self->get_sock();  # Here we create the socket handle

      socket($self->socket(), PF_INET, SOCK_STREAM, $proto) || carp "Unable to create socket: $!"; # create a socket

      if($port =~ /\D/) {
        $port = getservbyname($port, 'tcp');
      }
      carp "Can't get port: $!" if $port == undef;

      if ($remote !~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/)
        {
          my ($name, $aliases, $addrtype, $length, @addrs) = gethostbyname $remote;
          my ($a, $b, $c, $d) = unpack('C4', $addrs[0]);

          $remote = "$a.$b.$c.$d";
        }

      $iaddr = inet_aton($remote) ||  carp "Can't get remote address: $!";
      $paddr   = sockaddr_in($port, $iaddr); 
  
      $proto = getprotobyname('tcp') || carp "No such protocol: $!";
    }
  else
    {
      $self->{'socket'} = $socket;
    }

  # Make the socket non-blocking
  if (! $blocking)
    { fcntl($self->socket(), F_SETFL, O_NONBLOCK); }

  if ($socket eq undef)
    {
      connect($self->socket(), $paddr) || ($self->{'Delayed'} = "Yes");
    }

  $self->{'fileno'} = fileno($self->socket());
    
  return $self;
}

sub delayedConnect {
  my $self = shift;

  my $ret;
  # 0 on sucess, errno on failure.
  $ret = getsockopt($self->socket(), SOL_SOCKET, SO_ERROR);
  
  if($ret != EALREADY && $ret != EINPROGRESS) {
    $self->{'Delayed'} = "No";
  }
  return $ret;
  
}

sub socket {
  my $self = shift;

  return $self->{'socket'};
}

sub read {
  my $self = shift;
  my %params = @_;

  my ($data, $length);
  $length = sysread($self->socket(), $data, $params{'-Length'} ?  $params{'-Length'} : 1024);
  return ($length, $data);
  
}

sub write {
  my $self = shift;
  my %params = @_;

  my $length;
  $length = syswrite($self->socket(), $params{'-Data'}, $params{'-Length'} ?  $params{'-Length'} : undef);
  return $length;
}

sub get_sock {
  return new IO::Handle;
}

1;

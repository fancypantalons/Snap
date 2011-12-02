#
# This is a socket-based control module for Snap.  It allows you to
# telnet to the port defined, log in with the specified password, and
# control Snap from a textmode interface.  This is useful for running
# Snap in the background and then connecting to control it periodically.
#
# Variables:
#
#   $sock_addr     - Address to listen on.  Default: 127.0.0.1
#   $sock_port     - Port to listen on.     Default: 2323
#   $sock_password - Password needed to gain access to Snap.  Required.
#   @sock_disabled - Disabled command list. Default: ('/eval', '/alias', '/exec');
#

$VERSION = "0.01";

use IO::Socket;
use FileHandle;

if (defined $SOCK_ENABLED)
{
  print "~5Error, sock already loaded!\n";
  return;
}

$sock_addr = (defined $sock_addr) ? $sock_addr : '127.0.0.1';
$sock_port = (defined $sock_port) ? $sock_port : 2323;
@sock_disabled = ('/eval', '/alias', '/exec') if ($#sock_disabled < 0);

my $server_sock = new IO::Socket::INET(LocalAddr => $sock_addr,
				       LocalPort => $sock_port,
				       Listen => 1,
				       Reuse => 1);
my $client = undef;
my $verified = undef;
my $obj = SockWindow->new(tied *STDOUT);

tie *STDOUT, 'SockWindow', $obj;

$handles{$server_sock} = { Handle => $server_sock,
			   Callback => \&handle_socket };

print "~13;Sock~c; $VERSION loaded... running on $sock_addr:$sock_port\n";

$command_hash{"/shutdown"} = "/quit";
$command_hash{"/disconnect"} = 
  sub 
    { 
      $obj->set_socket(undef);

      delete $handles{$client};

      $client->close();  
      $client = undef; 
      $verified = undef;
    };

sub handle_socket
{
  my ($sock, $handle) = @_;

  if ($handle eq $server_sock)
    {
      my $cl = $handle->accept();
      my $name = $cl->peerhost();

      return if (defined $client);
      $client = $cl;

      print "New terminal connection from $name.\n";
      debug_print("Sock", "New terminal connection from $name.\n");

      $handles{$client} = { Handle => $client,
			    Callback => \&handle_socket };

      $obj->set_socket($client);

      print "Password: ";
    }
  elsif ($handle eq $client)
    {
      my $cmd = <$handle>;

      $cmd =~ s/\015|\012//g;      

      if (! defined $verified)
        {
	  if ($cmd ne $sock_password)
	    {
	      print $handle "Error, incorrect password!\n";

              $obj->set_socket(undef);

	      delete $handles{$handle};
	      $client = undef;
	      $verified = undef;

	      return;
	    }
	  
          print "Password verified!\n";

	  $verified = 1;

	  return;
        }

      if (length($cmd) > 0)
        {
          my $bad = 0;

          $cmd =~ s/^\/quit/\/disconnect/;

          foreach (@sock_disabled)
            {
              if ($cmd =~ /^\Q$_\E/)
                {
                  print "That is a restricted command, sorry!\n";
                  $bad = 1;
                }
            }

          debug_print("Sock", "Executing command: $cmd\n");          
          do_command($sock, $cmd)  if (! $bad);
        }
      else
        {	    
          $obj->set_socket(undef);

	  delete $handles{$handle};
	  $client = undef;
	  $verified = undef;
        }
    }
}

package SockWindow;

sub new
{
  my $class = shift;
  my $self = {};

  bless $self, $class;

  $self->{"window"} = shift;
  $self->{"socket"} = undef;

  return $self;
}

sub set_socket
{
  my $self = shift;

  $self->{"socket"} = shift;
}

sub print
{
  my ($self, $text) = @_;
  my $sock = $self->{"socket"};

  if (defined $self->{"window"})
    { $self->{"window"}->print("$text") }

  return if (! $sock);

  $text =~ s/~.*?;//g;

  print $sock $text;
}

sub TIEHANDLE
{
  my $class = shift;
  my $obj = shift;

  return $obj;
}

sub WRITE
{
  my $self = shift;

  $self->print("WRITE not supported...\n");
}

sub PRINT
{
  my $self = shift;
  my $var;

  foreach $var (@_)
    { $self->print($var); }
}

sub PRINTF
{
  my $self = shift;

  $self->print("PRINTF not supported...\n");
}

sub READ
{
  my $self = shift;

  $self->print("On STDIN?  Nuhuh...\n");
}

sub READLINE
{
  my $self = shift;

  $self->print("On STDIN?  Nuhuh...\n");
}

sub GETC
{
  my $self = shift;

  $self->print("On STDOUT?  Nuhuh...\n");
}

sub CLOSE
{
  my $self = shift;
  
  $self->print("CLOSE not supported...\n");
}

sub DESTROY
{
}

1;



package SnapLib::NapSocket;

use IO::Socket;
use SnapLib::Debug;

@ISA = qw(IO::Socket::INET);

sub new
{
  my $class = shift;
  my ($metaserver, $metaport, $ip, $port, $delay) = @_;

  if ((! defined $ip) || (! defined $port))
    { ($ip, $port) = get_best_host($metaserver, $metaport, $delay); }

  my $self = $class->SUPER::new(PeerAddr => $ip,
                                PeerPort => $port,
				Proto => 'tcp');

  return undef if (! defined $self);

  ${*$self}{"buffer"} = "";
  ${*$self}{"buflen"} = 0;

  return $self;
}

sub send
{
  my $self = shift;
  my $cmd = shift;
  my $data = shift;
  my $wait = shift;
  my $sent;

  my $type = pack("v", $cmd);
  my $length = pack("v", length $data);
  my $message = "$length$type$data";

  debug_print("Send", "Command: $cmd, Data: $data\n");

  do
    {
      $sent = $self->syswrite($message, length $message);
    }
  while ((defined $wait) && ($sent == 0));

  return $sent;
}

sub get
{
  my $self = shift;
  my ($data, $len);
  my $cmd_length;
  my $cmd_data;
  my $cmd;

  if (${*$self}{"buflen"} < 4)
    {      
      $len = $self->sysread($data, 4 - ${*$self}{"buflen"});

      return undef if ($len == 0);

      ${*$self}{"buffer"} .= $data;
      ${*$self}{"buflen"} += $len;

      return (-1, "") if (${*$self}{"buflen"} < 4);
    }

  $cmd_length = unpack("v", substr(${*$self}{"buffer"}, 0, 2)); 

  if (${*$self}{"buflen"} - 4 < $cmd_length)
    {
      $len = $self->sysread($data, $cmd_length - (${*$self}{"buflen"} - 4));
      return undef if ($len == 0);

      ${*$self}{"buffer"} .= $data;
      ${*$self}{"buflen"} += $len;
    }

  return (-1, "") if (${*$self}{"buflen"} - 4 < $cmd_length);

  $cmd = unpack("v", substr(${*$self}{"buffer"}, 2, 2));
  $actual_string = substr(${*$self}{"buffer"}, 4, $cmd_length);

  ${*$self}{"buffer"} = substr(${*$self}{"buffer"}, $cmd_length + 4);
  ${*$self}{"buflen"} -= $cmd_length + 4;

  debug_print("Receive", "command = $cmd, " . "data = $actual_string\n"); 

  return ($cmd, $actual_string);
}

sub get_best_host
{
  my ($metaserver, $metaport, $delay) = @_;
  my ($host, $port) = (undef, undef);

  print "Getting a host from $metaserver:$metaport...";  

  do
    {
      print ".";

      my $napsrv = IO::Socket::INET->new(PeerAddr => $metaserver,
                                         PeerPort => $metaport,
                                         Proto => 'tcp');
      my ($data, $len);
      my $sel = new IO::Select($napsrv);

      if($sel->can_read($delay))
        {
          $len = $napsrv->sysread($data, 20);

          $napsrv->close();
          
          $data =~ s/\012|\0//g;
          $data =~ /(\d+?\.\d+?\.\d+?\.\d+?):(.*)/;
          
          $host = $1; $port = $2;
          
          if ($host =~ /127\.0\.0\.1/)
            { select(undef, undef, undef, $delay); }
        }
      else 
        { $napsrv->close(); }
    }
  while (($host =~ /127\.0\.0\.1/) || (! defined $host));

  if ((! defined $host) || (! defined $port))
    {
      print "\nError getting host!\n";
      exit(255);
    }

  debug_print("Init", "Connecting to $host:$port...\n");

  print "\nGot host $host:$port...\n";

  return ($host, $port);  
}

1;

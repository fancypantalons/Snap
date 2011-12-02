#
# This is a very simple remote control system for Snap. This is meant 
# for those times when you want to set up a stand-alone Snap server.  
# It allows you to set up the client as a background process and 
# communicate with it via messages on the Napster server itself.  Kinda 
# handy for weird situations, and demonstrates the power of scripting 
# in Snap.
#
# This new version, which replaces the original remote.pl script,
# is MUCH more stable, since it uses a much simpler system for trapping
# screen printing (Snap's standard tie() system).  Thus, the stability
# is greatly increased.  As well, it has some newer features, like
# the ability to disable specific commands, for enhanced security.
#
# Make sure you define these variables before you load this script:
#
# $remote_password - Password used to gain control over the client.
# @allowed         - List of nicks allowed to control this client.
# @disabled        - List of disabled commands.  ie, commands which 
#                    aren't allowed to run remotely (ie, /eval, /exec).
#
# To gain control of the client, send a private message to the client
# with the text: verify password
#
# The client will then return an ACK or a NAK.  If it's an ACK, you
# then send commands by sending a message to the client with the
# desired command.  Easy! :)
#

package RemoteWindow;

#
# This part of the module comprises the replacement screen routines,
# used to transparently send the text output through the socket to the
# remote user.  This part of the code provides an excellent template for
# modules which wish to intercept the screen printing and deal with the
# text themselves.
#

use SnapLib::MessageTypes;

# Print function... emulates buffered output to ensure proper line
# breaking, etc.

sub print
{
  my ($self, $text) = @_;
  my $handle = $self->{"handle"};

  if (defined $self->{"window"})
    { $self->{"window"}->print("$text") }

  return if ($main::user eq undef);

  $text =~ s/~.*?;//g;

  while ($text ne "")
    {
      # Now the guts...

      my $line;
      my $pos = index($text, "\n") + 1;

      if ($pos > 0)
        { $line = substr($text, 0, $pos); }
      else
        { $line = $text; }

      $text =~ s/^\Q$line\E//;

      $self->{"buffer"} .= $line;

      if ($line =~ /\n/)
        {
	  my $buf = $self->{"buffer"};

	  $buf =~ s/(\s+?)$//g;

	  $napster_sock->send(MSG_PRIVATE, "$::user |$buf");
	  $self->{"buffer"} = "";
	};
    }
}

sub TIEHANDLE
{
  my $class = shift;
  my $self = {};
  my $obj = tied(*STDOUT);

  bless $self, $class;
  $self->{"window"} = $obj;
  $self->{"total"} = 0;
  $self->{"handle"} = shift;

  return $self;
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

###############################################################################

package main;

my $user = undef;
my @verified;
my $bottom = 0;
my $active = 1;

$REMOTE_VERSION = "0.02";

print "~13;Remote Controller~c; $REMOTE_VERSION loaded...\n";

local *H = *STDOUT;
tie *STDOUT, 'RemoteWindow', *H;  # Tie our remote windowing code to STDOUT

sub send_message
{
  $_[0]->send(MSG_PRIVATE, $_[1]);
}

sub msg_handler
{
  my ($sock, $text) = @_; 
  my $cmd;
  $$text =~ /(.+?) (.*)/;  
  my $u = $1; $cmd = $2;

  if (($cmd =~ /^verify\s+(.*)/i) && grep (/\Q$u\E/, @allowed))
    {
      if ($1 eq $remote_password)
        {
          push @verified, $u;
          send_message($napster_sock, 
			      "$u Verification succeeded.  Welcome $u!");

          return;
         }
      else
        {
          send_message($napster_sock,
			      "$u Error, verification failed.");
          return;
        }
    }
  elsif (! grep (/\Q$u\E/, @verified) && ($cmd =~ /^verify\s+(.*)/i))
    {
      send_message($napster_sock,
                          "$u Error, you aren't allowed access to this client.");
      return;
    }
  elsif (! grep (/\Q$u\E/, @verified) && ($cmd !~ /^verify\s+(.*)/i))
    { return; }

  if ($cmd =~ /^disconnect$/i)
    {
      send_message($napster_sock, "$u Disconnecting view.");
      $::user = undef;

      return;
    }

  $::user = $u;

  debug_print("Remote", "Executing $cmd...\n");

  my $entry;

  foreach $entry (@disabled)
    {     
      if ($cmd =~ /^\Q$entry\E/i)
        {
	  send_message($napster_sock, 
			      "$u Sorry, that command is disabled.");
	  return;
        }
    }  

  return if (! $active);

  do_command($sock, $cmd);
}

sub do_remote_setup
{
  my ($sock, $param_str, @params) = @_;
  my %opts = ("disable" => 0,
              "enable" => 0,
              "version" => 0);

  my $results = getopts(\%opts, \@params);

  return if (! defined $results);

  if (defined $results->{"disable"})
    {
      $active = 0;
      print "Disabling Remote Controller...\n";
    }
  
  if (defined $results->{"enable"})
    {
      $active = 1;
      print "Enabling Remote Controller...\n";
    }

  if (defined $results->{"version"})
    {
      print "Remote Controller version $VERSION\n";
    }
}

sub do_remote_help
{
  return "Usage: /remote [options]

  Sets options for the Remote Controller module.  Options include:

    -ENABLE  - Enables Remote Controller
    -DISABLE - Disables Remote Controller
    -VERSION - Display Remote Controller version.
";
}

push @{ $code_hash{&MSG_PRIVATE} }, \&msg_handler;

$command_hash{"/remote"} = [\&do_remote_setup];
$help_hash{"/remote"} = \&do_remote_help;

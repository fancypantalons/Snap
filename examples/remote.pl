#
# This is a very simple remote control system for a snap client.
# This is meant for those times when you want to set up a
# stand-alone Snap server.  It allows you to set up the client
# as a background process and communicate with it via messages
# on the Napster server itself.  Kinda handy for weird situations,
# and demonstrates the power of scripting in Snap.
#

my $user = undef;
my @verified;
my $bottom = 0;

push @extensions, "Remote";

sub remote_print
{
  my $window = shift;
  my $text = shift;
  my $state = shift;
  my $color = shift;

  return if ($::user eq undef);

  my @lines = @{ $$state{"buffer"} };
  my $cnt = $$state{"lines"};

  if ($bottom < $cnt)
    {
      my $i;

      for ($i = $bottom; $i < $cnt; $i++)
        {
          my $line = $lines[$i];

          if (chomp($line))
            {
              send_to_server($napster_sock, MSG_PRIVATE, "$::user \|$line");
              $bottom = $i + 1;
            }
        }
    }
}

sub msg_handler
{
  my ($sock, $text, $textwin, $text_state, $cmdwin, $line_state) = @_; 
  my $cmd;
  $$text =~ /(.+?) (.*)/;  
  my $u = $1; $cmd = $2;

  if (($cmd =~ /^verify (.*)/) && (grep /\Q$u\E/, @allowed))
    {
      if ($1 eq $remote_password)
        {
          push @verified, $u;

          do_send_private_msg($napster_sock, $win[0], \%text_state, undef, undef,
                          "$u Verification succeeded.  Welcome $u!");

          $bottom = $#{ $$text_state{"buffer"} } + 1;
          return;
         }
      else
        {
          do_send_private_msg($napster_sock, $win[0], \%text_state, undef, undef,
                          "$u Error, verification failed.");
          return;
        }
    }
  elsif (! grep /\Q$u\E/, @verified)
    {
      do_send_private_msg($napster_sock, $win[0], \%text_state, undef, undef,
                          "$u Error, you aren't verified!");
      return;
    }

  if ($cmd =~ /^disconnect$/)
    {
      do_send_private_msg($napster_sock, $win[0], \%text_state, undef, undef,
                          "$u Disconnecting view.");      

      $::user = undef;

      return;
    }

  $::user = $u;

  print_debug("Remote", "Executing $cmd...\n");

  $$line_state{"line"} = $cmd;

  do_command($sock, $textwin, $text_state, $cmdwin, $line_state);
}

push @{ $code_hash{&MSG_PRIVATE} }, \&msg_handler;
push @{ $window_hash{"print"} }, \&remote_print;

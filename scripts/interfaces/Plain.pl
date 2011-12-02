#
# Plain text interface module.
#

$INTERFACE = 1;

my $VERSION = "0.01";

BEGIN
{
  if ((defined $INTERFACE) || ($daemon)) { $SUCCESS = 0; return 1; }

  foreach (@SCRIPT_PATH)
    {
      push @INC, "$_/PlainLib";
    }

  my $oh = $SIG{__DIE__};

  $SIG{__DIE__} = sub { return; };

  eval
    {
      require StdWindow;
      import StdWindow;
    };

  $SIG{__DIE__} = $oh;

  if ($@)
    {
      print "Error, unable to load Plain module...\n";

      $SUCCESS = 0;

      return 1;
    }
  else
    {
      $SUCCESS = 1;
    }
}

return if (! $SUCCESS);

#
# Install keyboard handler;
#

my $handle = \*STDIN;
$handles{$handle} = { Handle => $handle,
                      Callback => \&check_keyboard };

#
# Set up screen.
#

push @{ $code_hash{&MSG_INIT} }, \&setup_basic_screen;

sub setup_basic_screen
{ 
  my ($win, $input);
  my $obj = tied *STDOUT;

  local *H = *STDOUT;

  $win = new StdWindow(*H, $obj);

  tie *STDOUT, 'StdWindow', $win;
      
  return ($win, undef);   
}

sub check_keyboard
{
  my ($sock, $handle) = @_;
  my $ch;
  my $line = <STDIN>;

  chomp($line);
  do_command($sock, $line);
}

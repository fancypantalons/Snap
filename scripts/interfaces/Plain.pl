#
# Plain text interface module.
#

if ((defined $INTERFACE) || ($daemon)) { return 1; }

$INTERFACE = 1;

my $VERSION = "0.01";

BEGIN
{
  foreach (@SCRIPT_PATH)
    {
      push @INC, "$_/PlainLib";
    }
}

use StdWindow; 

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

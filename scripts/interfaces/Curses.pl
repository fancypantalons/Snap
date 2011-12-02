#
# Curses interface module.
#

if ((defined $INTERFACE) || ($daemon)) { return 1; }

my $VERSION = "0.01";

BEGIN
{
  foreach (@SCRIPT_PATH)
    {
      push @INC, "$_/CursesLib";
    }

  eval { require Curses; import Curses };

  if ($@)
    {
      print "Error, unable to load Curses module...\n";
      return;
    }
}

use Window; 
use InputLine;

push @{ $code_hash{&MSG_SERVER_STATS} }, \&update_counts;
push @{ $code_hash{&MSG_INIT} }, \&setup_curses;

$INTERFACE = 1;
$SCROLL_LENGTH = 101 if (! defined $SCROLL_LENGTH);

push @extensions, "Curses";
print "Curses TUI Module $VERSION Loaded...\n";

#
# Set up keyboard handler
#

my $handle = \*STDIN;
$handles{$handle} = { Handle => $handle,
                      Callback => \&check_keyboard };

$command_hash{"/pageup"} = [ \&do_page_up ];
$command_hash{"/pagedown"} = [ \&do_page_down ];
$command_hash{"/clear"} = [ \&do_clear ];

$help_hash{"/pageup"} = "Usage: /pageup\n\n  Causes the screen to shift up by a half-page.\n\n";
$help_hash{"/pagedown"} = "Usage: /pagedown\n\n  Causes the screen to shift down by a half-page\n\n";
$help_hash{"/clear"} = "Usage: /clear\n\n  Clears the display.\n\n";

#
# Set up screen.
#

my ($window, $input);

$CURSES_ENABLED = 1;

unshift @{ $code_hash{&MSG_SHUTDOWN} }, sub { endwin() };

sub setup_curses
{
  my $tieclass;

  my $textwin;
  my $cmdwin;
  my ($scr_width, $scr_height);

  initscr(); 
  cbreak();
  noecho();
      
  # This is a butt-ugly palette which tries to emulate the GUI palette
  # to some degree... what Curses needs is the ability to store attributes
  # in colour pairs...

  if ($colours)
    {
      start_color();
      
      init_pair(1, COLOR_YELLOW, COLOR_BLACK);
      init_pair(2, COLOR_WHITE, COLOR_BLACK);    
      init_pair(3, COLR_BLUE, COLOR_BLACK);
      init_pair(4, COLOR_GREEN, COLOR_BLACK);
      init_pair(5, COLOR_RED, COLOR_BLACK);
      init_pair(6, COLOR_MAGENTA, COLOR_BLACK);
      init_pair(7, COLOR_MAGENTA, COLOR_BLACK);
      init_pair(8, COLOR_YELLOW, COLOR_BLACK);
      init_pair(9, COLOR_YELLOW, COLOR_BLACK);
      init_pair(10, COLOR_GREEN, COLOR_BLACK);
      init_pair(11, COLOR_GREEN, COLOR_BLACK);
      init_pair(12, COLOR_CYAN, COLOR_BLACK);
      init_pair(13, COLOR_BLUE, COLOR_BLACK);
      init_pair(14, COLOR_WHITE, COLOR_BLACK);
      init_pair(15, COLOR_WHITE, COLOR_BLACK);
      init_pair(16, COLOR_WHITE, COLOR_BLUE);
    }
  
  getmaxyx($scr_height, $scr_width);
  $textwin = subwin($scr_height-2, $scr_width, 0, 0);
  $cmdwin = subwin(2, $scr_width, $scr_height-2, 0);
      
  attrset($cmdwin, COLOR_PAIR(16));
  addstr($cmdwin, 0, 0, "-"x$scr_width);
  attrset($cmdwin, COLOR_PAIR(2));

  my $oldwin = tied *STDOUT;
  
  ($window, $input) = (Window->new($textwin, $SCROLL_LENGTH, $oldwin),
                       InputLine->new($cmdwin));

  tie *STDOUT, 'Window', $window;

  refresh($cmdwin);
}

sub check_keyboard
{
  my ($sock, $handle) = @_;
  my $ch;

  $input->getchar($ch);
  return if ($input->line_available() == $FALSE);

  do_command($sock, $input->getline());
}

sub update_counts
{
  my ($sock, $text) = @_;
  my ($libs, $total, $gigs);

  $$text =~ s/(\d+) (\d+) (\d+)//g;
  $total = $2; $libs = $1; $gigs = $3;   

  return if (! isa($input->{"window"}, 'Curses::Window'));

  attrset($input->{"window"}, COLOR_PAIR(16));
  addstr($input->{"window"}, 0, 0, "-- Songs: $total -- Libraries: $libs -- Gigs: $gigs ");
  attrset($input->{"window"}, COLOR_PAIR(2));

  refresh($input->{"window"});
}

sub do_page_up
{
  my ($sock, $param_str, @params) = @_;

  $window->page_up;
}

sub do_page_down
{
  my ($sock, $param_str, @params) = @_;

  $window->page_down;
}

sub do_clear
{
  my ($sock, $param_str, @params) = @_;

  $window->clear;
}

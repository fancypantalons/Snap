# Module to make use of the StdWindow and StdinLine modules to
# allow textmode, non-curses operation...

use Snap::StdWindow;
use Snap::StdinLine;

sub setup_screen
{
  my ($win, $input);
  local *H = *STDOUT;

  $win = new Snap::StdWindow(*STDOUT);
  $input = new Snap::StdinLine();

  tie *STDOUT, 'Snap::StdWindow', $win;

  return ($win, $input);
}

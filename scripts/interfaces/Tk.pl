#
# Perl/Tk Interface Scripts.  Currently only provides a text window and
# input line.
#

my $VERSION = "0.01";

BEGIN
{
  if ((defined $INTERFACE) || ($daemon)) { $SUCCESS = 0; return 1; }

  foreach (@SCRIPT_PATH)
    {
      push @INC, "$_/TkLib";
    }

  if (! $TK_ENABLED)
  {
    eval_file("TkImport.pl");
  }

  my $oh = $SIG{__DIE__};

  $SIG{__DIE__} = sub { return; };

  eval
    {
      require TkTextPrinter;
      import TkTextPrinter;
    };

  $SIG{__DIE__} = $oh;

  if ($@)
    {
      print "Error, unable to load Tk module...\n";

      $SUCCESS = 0;

      return 1;
    }
  else
    {
      $SUCCESS = 1;
    }
}

return if (! $SUCCESS);
      
if (! $TK_ENABLED)
{
  print "Tk Import Module not loaded!\n";
  return 1;
}

$INTERFACE = 1;

push @{ $code_hash{&MSG_INIT} }, \&setup_gui;

sub setup_gui
{
  my $main = $MainWin;
  my $font = $main->Font(family => 'fixed', slant => 'r', point => 120, weight => 'medium');
 
  my $text = $main->Scrolled('ROText', -font => $font, -scrollbars => 'ose');
  my $entry = $main->Entry();

  $text->configure(-background => "black");

  $text->pack(-expand => 1, -fill => 'both');
  $entry->pack(-fill => 'x');

  $entry->bind("<KeyPress-Return>", sub { do_command($napster_sock,
						     $entry->get());
					  $entry->delete("0", "end") });

  tie *STDOUT, 'TkTextPrinter', $text;
}


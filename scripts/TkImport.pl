#
# Tk Import Module
#
# This module functions as a transparent Tk wrapper around Snap, much like
# the GtkImport module.  In fact, the code is almost identical.
#

use SnapLib::HandleWrapper;

if (tied %handles)
{
  print "Unable to load Tk Import module... existing wrapper detected!\n";
  return 1;  
}

my $VERSION = "0.01";

BEGIN
{
  eval "use Tk";

  if ($@)
    {
      print "Error, unable to load Tk Import module...\n";
      return 1;
    }
}

$TK_ENABLED = 1;

if ($TK_ENABLED)
{
  my %temp = %handles;

  tie %handles, 'HandleWrapper', \&add_handle, \&remove_handle;

  foreach (keys %temp) { $handles{$_} = $temp{$_}; }

  push @extensions, "Tk";
  print "Tk Import Module $VERSION Loaded...\n";

  $MainWin = new MainWindow(-title => 'Snap');

  *main_loop = *main_tk;  # Overwrite the main loop sub.
}
else
{
  print "Error initializing Tk...\n";
  return;
}

sub main_tk { MainLoop; }

sub add_handle
{
  my $data = shift;

  Tk::fileevent(undef, $data->{Handle}, 'readable',
                        sub { $data->{Callback}->($napster_sock,
                              $data->{Handle})} );
}

sub remove_handle
{
  my $data = shift;

  Tk::fileevent(undef, $data->{Handle}, 'readable', undef);
}

1;

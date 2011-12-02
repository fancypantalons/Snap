#
# Tk Import Module
#
# This module functions as a transparent Tk wrapper around Snap, much like
# the GtkImport module.  In fact, the code is almost identical.
#

use SnapLib::HandleWrapper;

my $VERSION = "0.01";

BEGIN
{
  if (tied %handles)
    {
      $SUCCESS = 0;
      return 1;  
    }

  my $oh = $SIG{__DIE__};

  $SIG{__DIE__} = sub { return; };

  eval 
    { 
      require Tk; 
      import Tk; 
    };

  $SIG{__DIE__} = $oh;

  if ($@)
    {
      print "Error, unable to load Tk Import module...\n";

      $SUCCESS = 0;

      return 1;
    }
  else
    {
      $SUCCESS = 1;
    }
}

return if (! $SUCCESS);

eval {
  $MainWin = new MainWindow(-title => 'Snap');
};

if ($@)
  {
    $TK_ENABLED = 0;
  }
else
  {
    $TK_ENABLED = 1;
  }

if ($TK_ENABLED)
{
  my %temp = %handles;

  tie %handles, 'HandleWrapper', \&add_handle, \&remove_handle;

  foreach (keys %temp) { $handles{$_} = $temp{$_}; }

  push @extensions, "Tk";
  print "Tk Import Module $VERSION Loaded...\n";

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

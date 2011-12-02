#
# Gtk Import Module
#
# This module functions as a transparent Gtk wrapper around Snap.  
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
      require Gtk; 
      import Gtk; 

      require Gtk::Atoms;
      import Gtk::Atoms;

      require Gtk::Keysyms;
      import Gtk::Keysyms;
    };

  $SIG{__DIE__} = $oh;

  if ($@)
    {
      print "Error, unable to load Gtk Import module...\n";

      $SUCCESS = 0;

      return 1;
    }
  else
    {
      $SUCCESS = 1;
    }
}

return if (! $SUCCESS);

$GTK_ENABLED = init_check Gtk;

if ($GTK_ENABLED)
{
  my %temp = %handles;

  tie %handles, 'HandleWrapper', \&add_handle, \&remove_handle;

  foreach (keys %temp) { $handles{$_} = $temp{$_}; }

  push @extensions, "Gtk";
  print "Gtk Import Module $VERSION Loaded...\n";

  *main_loop = *main_gtk;  # Overwrite the main loop sub.
}
else
{
  print "Error initializing Gtk...\n";
  return;
}

sub main_gtk { main Gtk; }

sub add_handle
{
  my $data = shift;

  $data->{Tag} = Gtk::Gdk->input_add(fileno($data->{Handle}), 'read',
                                     sub { $data->{Callback}->($napster_sock,
                                                               $data->{Handle}) });
}

sub remove_handle
{
  my $data = shift;

  Gtk::Gdk->input_remove($data->{Tag});
}

1;

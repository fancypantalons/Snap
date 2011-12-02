#
# Gtk Import Module
#
# This module functions as a transparent Gtk wrapper around Snap.  
#

use SnapLib::HandleWrapper;

if (tied %handles)
{
  print "Unable to load Gtk Import module... existing wrapper detected!\n";
  return 1;  
}

my $VERSION = "0.01";

BEGIN
{
  eval "use Gtk; use Gtk::Atoms; use Gtk::Keysyms";

  if ($@)
    {
      print "Error, unable to load Gtk Import module...\n";
      return 1;
    }
}

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

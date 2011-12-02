#
# A weird little module that lets you load Perl/Gtk into Snap and actually
# use it... You could go to the extent of adding a whole Gtk interface,
# if you wanted, through a mechanism something like this.  Perhaps just
# rewrite print_to_window and a couple others, and there you have it... :)
#
# Note, this module MUST be run on startup in your RC file... if not,
# the main loop code won't be inserted, and GTK won't work... I've tried
# it... it breaks. :)
#

eval "use Gtk; use Gtk::Atoms; init Gtk;";

push @extensions, "Gtk";

if ($@)
  {
    print_to_window($textwin, "Error, unable to load GTK module...\n", 
                    $text_state, 1);
    return;
  }

$POLL_DELAY = 0.01;  # Make the select() poll really short, to keep GTK
                     # responsive.

$GTK_ENABLED = 1;    # For other module use...

print_to_window($textwin, "Gtk Module $VERSION Loaded...\n", $text_state, 1);

eval '
sub main_loop
{
  my %line_state = ("buffer" => "",
                    "status" => $FALSE,
                    "pos" => 0,
                    "length" => 0,
                    "history" => (""));
  my %text_state;
  my $nap_buffer;
  my $total = -1;
  my $func;

  Gtk->idle_add(
    sub {
      my $func;

      wait_for_input($napster_sock, $server_sock, $win[0], \%text_state,
                     $win[1], \%line_state, \$nap_buffer, \$total);

      foreach $func (@poll_funcs) # Check polled functions
        {
          &$func($napster_sock, $win[0], \%text_state, $win[1], \%line_state, \$nap_buffer, \$total);
        }

      if (! $daemon)
        {
          noutrefresh($win[0]);
          noutrefresh($win[1]); doupdate();
        }

      return 1;
    }
  );

  main Gtk;
}';

############################## Utility Functions ########################

sub kill_widget
{
  my $w = shift;
  my $widget = shift;
  $widget->destroy;
}


#
# Implements a simple perl source editor/console/interactive thingy. :)
# This is super-handy when you're creating new modules and stuff...
#

$VERSION = "0.01a";

push @extensions, "Perl Console";

if (! $GTK_ENABLED)
  {
    print_to_window($textwin, "Error, Gtk module isn't loaded...\n", $text_state, 1);
    return;
  }

$command_hash{"/pconsole"} = [\&do_perl_console];
$help_hash{"/pconsole"} = "Usage: /pconsole\n\n  Display the Perl Console window.\n\n";

print_to_window($textwin, "Perl Console $VERSION Loaded...\n", $text_state, 1);

sub do_perl_console
{
  my ($window, $textbox, $vbox, $hbox, $button, $scroller);
  my $menubar = new Gtk::MenuBar;
  my $menu = new Gtk::Menu;

  $window = Gtk::Window->new;  
  $window->set_title("Perl Console");
  $vbox = Gtk::VBox->new(0, 0);
  $window->add($vbox);
  $vbox->show;

  $vbox->pack_start($menubar, 0, 0, 0);
  $menubar->show;

  $window->signal_connect("delete_event", \&kill_widget, $window);
  $window->signal_connect("delete_event", sub { $window->{'file_load_opened'} = 0; });
  $window->signal_connect("delete_event", sub { $window->{'file_save_opened'} = 0; });

  $window->set_usize(400, 200);

  $scroller = Gtk::ScrolledWindow->new;
  $scroller->set_policy('automatic', 'automatic');
  $vbox->pack_start($scroller, 1, 1, 0);
  $scroller->show;

  $textbox = Gtk::Text->new;
  $textbox->set_editable(1);
  $scroller->add($textbox);
  $textbox->show;

  $hbox = Gtk::HBox->new(0, 0);
  $vbox->pack_start($hbox, 0, 0, 5);
  $hbox->show;

  $button = Gtk::Button->new_with_label("Run");
  $button->signal_connect("clicked", \&eval_perl_code, $textbox);
  $hbox->pack_start($button, 0, 0, 5);
  $button->show;

  $button = Gtk::Button->new_with_label("Clear");
  $button->signal_connect("clicked", \&clear_perl_console, $textbox);
  $hbox->pack_start($button, 0, 0, 5);
  $button->show;

  $menuitem = new Gtk::MenuItem("Load Source");
  $menu->append($menuitem);
  $menuitem->signal_connect("activate", \&load_perl_source, $textbox, 1);
  $menuitem->show;

  $menuitem = new Gtk::MenuItem("Save Source");
  $menu->append($menuitem);
  $menuitem->signal_connect("activate", \&save_perl_source, $textbox);
  $menuitem->show;

  $menuitem = new Gtk::MenuItem("Insert File");
  $menu->append($menuitem);
  $menuitem->signal_connect("activate", \&load_perl_source, $textbox, 1);
  $menuitem->show;

  $menuitem = new Gtk::MenuItem("Close Console");
  $menu->append($menuitem);
  $menuitem->signal_connect("activate", \&kill_widget, $window);
  $menuitem->show;

  $menuitem = new Gtk::MenuItem("File");
  $menuitem->set_submenu($menu);
  $menubar->append($menuitem);
  $menuitem->show;
  $clients{$pid}{'channels'}{$channel}{'file_menu_item'} = $menuitem;

  $window->show;
}

sub eval_perl_code
{
  my $widget = shift;
  my $textbox = shift;
  my $text;

  $text = $textbox->get_chars(0, $textbox->get_length);

  eval $text;

  print STDERR $@;
}

sub clear_perl_console
{
  my $widget = shift;
  my $textbox = shift;

  $textbox->set_point(0);
  $textbox->forward_delete($textbox->get_length);
}

############################### File Save Code ############################

sub load_perl_source
{
  my $window = shift;
  my $textbox = shift;
  my $overwrite = shift;

  if ($window->{'file_load_opened'}) { return; }

  $window->{'file_load_opened'} = 1;

  my $fileselection = Gtk::FileSelection->new("Load Source");

  my $ok = $fileselection->ok_button;
  my $cancel = $fileselection->cancel_button;

  $ok->signal_connect("clicked", \&do_source_load, $textbox, $fileselection, $overwrite);
  $ok->signal_connect("clicked", sub { $window->{'file_load_opened'} = 0; });
  $ok->signal_connect("clicked", \&kill_widget, $fileselection);

  $cancel->signal_connect("clicked", sub { $window->{'file_load_opened'} = 0; });
  $cancel->signal_connect("clicked", \&kill_widget, $fileselection);

  $fileselection->show;
}

sub do_source_load
{
  my $window = shift;
  my $textbox = shift;
  my $filesel = shift;
  my $overwrite = shift;
  my $filename = $filesel->get_filename;
  my @lines;
  my $line;
  local *FILE;

  if ($overwrite) { &clear_perl_console(undef, $textbox); }
  
  open(FILE, "<$filename");
  @lines = <FILE>;

  $textbox->freeze;

  $textbox->set_point($textbox->get_position);

  foreach $line (@lines)
    {
      $textbox->insert(undef, $textbox->style->black, undef, $line);
    }
  $textbox->thaw;
}

################################# File Save Code #########################

sub save_perl_source
{
  my $window = shift;
  my $textbox = shift;
  my $overwrite = shift;

  if ($window->{'file_save_opened'}) { return; }

  $window->{'file_save_opened'} = 1;

  my $fileselection = Gtk::FileSelection->new("Save Source");

  my $ok = $fileselection->ok_button;
  my $cancel = $fileselection->cancel_button;

  $ok->signal_connect("clicked", \&do_source_save, $textbox, $fileselection, $overwrite);
  $ok->signal_connect("clicked", sub { $window->{'file_save_opened'} = 0; });
  $ok->signal_connect("clicked", \&kill_widget, $fileselection);

  $cancel->signal_connect("clicked", sub { $window->{'file_save_opened'} = 0; });
  $cancel->signal_connect("clicked", \&kill_widget, $fileselection);

  $fileselection->show;
}

sub do_source_save
{
  my $window = shift;
  my $textbox = shift;
  my $filesel = shift;
  my $filename = $filesel->get_filename;
  my $text;
  local *FILE;

  $text = $textbox->get_chars(0, $textbox->get_length);

  open(FILE, ">$filename");

  print FILE "$text";
}

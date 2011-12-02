#
# This script is an example of how to create Perl/GTK GUI interfaces. 
# It also shows the use of the TextPrinter to display parsed text in a
# textbox.
#

my $VERSION = "0.01";

if (! $GTK_ENABLED)
  {
    print "Error, Gtk module isn't loaded...\n";
    return;
  }

$command_hash{"/colours"} = [\&do_colours];

$GUI{"menu_factory"}->create_item({ path => "/Plugins/Colour List",
				    accelerator => undef,
				    action => undef,
				    type => '<Item>' }, \&do_colours);

print "~4;C~5;o~6;l~7;o~8;u~9;r~c; Window $VERSION Loaded...\n";

my $win;

sub do_colours
{ 
  my $hbox = Gtk::HBox->new(0, 0);
  my $textbox = Gtk::Text->new();
  my $scroller = Gtk::VScrollbar->new($textbox->vadj);
  my $printer = SnapLib::GtkTextPrinter->new($textbox);
  my $style;
  my $i;

  return if (defined $win);

  $win = Gtk::Window->new();

  $win->add($hbox);
  $hbox->show();
  $win->signal_connect("delete_event", sub { $win->destroy; $win = undef; });
  $win->signal_connect("destroy", sub { $win->destroy; $win = undef; });

  $hbox->pack_start($textbox, 1, 1, 0);
  $textbox->show();
  $hbox->pack_start($scroller, 0, 0, 0);
  $scroller->show();

  $style = $textbox->style->copy;
  $style->base("normal", Gtk::Gdk::Color->parse_color("black"));
  $textbox->set_style($style);  

  $printer->print("~1;______________\n");
  $printer->print("Colour Listing\n");
  $printer->print("--------------\n~c;");

  for ($i = 0; $i <= 15; $i++)
    {
      if ($i < 10) 
        { $printer->print(" ~1;" . $i . ".  ~" . $i . ";Woah, colours...~c;\n"); }
      else     
        { $printer->print(" ~1;" . $i . ". ~" . $i . ";Woah, colours...~c;\n"); }
    }

  $textbox->show;
  $win->show;
}

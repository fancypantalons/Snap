package GtkTextPrinter;

sub new
{
  my $class = shift;
  my $self = {};
  my @colours;

  bless $self, $class;
  $self->{"colours"} = \@colours;  
  $self->{"text"} = shift;
  $self->{"window"} = shift;
  $self->{"last_colour"} = 1;
  $self->{"font"} = Gtk::Gdk::Font->load("-misc-fixed-medium-r-normal-*-*-130-*-*-c-*-iso8859-1");

  $colours[0] = Gtk::Gdk::Color->parse_color("black");
  $colours[1] = Gtk::Gdk::Color->parse_color("dark grey");
  $colours[2] = Gtk::Gdk::Color->parse_color("light grey");
  $colours[3] = Gtk::Gdk::Color->parse_color("dark blue");
  $colours[4] = Gtk::Gdk::Color->parse_color("green");
  $colours[5] = Gtk::Gdk::Color->parse_color("red");
  $colours[6] = Gtk::Gdk::Color->parse_color("magenta");
  $colours[7] = Gtk::Gdk::Color->parse_color("purple");
  $colours[8] = Gtk::Gdk::Color->parse_color("orange");
  $colours[9] = Gtk::Gdk::Color->parse_color("yellow");
  $colours[10] = Gtk::Gdk::Color->parse_color("green");
  $colours[11] = Gtk::Gdk::Color->parse_color("dark green");
  $colours[12] = Gtk::Gdk::Color->parse_color("cyan");
  $colours[13] = Gtk::Gdk::Color->parse_color("blue");
  $colours[14] = Gtk::Gdk::Color->parse_color("pink");
  $colours[15] = Gtk::Gdk::Color->parse_color("white");

  # Neat little hack so if the RGB database on an X server doesn't
  # have our colours, we just make them grey... ugly?  I think so. :)

  foreach (@colours)
    {
      if (! defined $_)
        { $_ = Gtk::Gdk::Color->parse_color("Grey"); }
    }

  return $self;
}

sub print
{
  my ($self, $text) = @_;
  my $i = 0;

  $self->{"window"}->print($text) if (defined $self->{"window"});

  while ($text ne "")
    {
      # Now the guts...

      my $line;
      my $pos = index($text, "\n") + 1;

      if ($pos > 0)
        { $line = substr($text, 0, $pos); }
      else
        { $line = $text; }
      
      $text =~ s/^\Q$line\E//;

      $self->insert($line);
    }
}

sub insert
{
  my $self = shift;
  my $line = shift;
  my ($colour, $nextcolour) = ($self->{"last_colour"}, 0);
  my $text;
  my $textbox = $self->{"text"}; 

  while ($line =~ /~(\d{1,2}|c);/)
    {
      $nextcolour = $1;
      $text = $line;
      
      $line =~ s/^.*?~\Q$nextcolour\E;//;
      $text =~ s/~\Q$nextcolour;$line\E$//;

      if ($nextcolour eq "c") { $nextcolour = 1; }
      
      $textbox->insert($self->{"font"}, $textbox->get_colormap->color_alloc($self->{"colours"}->[$colour]), undef, $text);
      
      $colour = $nextcolour;
      
      if ($colour > 15) { $colour = 15; }
    } 

  $textbox->insert($self->{"font"}, $textbox->get_colormap->color_alloc($self->{"colours"}->[$colour]), undef, $line);

  $self->{"last_colour"} = $colour;
}

sub clear
{
}

sub page_up
{
}

sub page_down
{
}

sub width
{
  return 80;
}

sub height
{
  return 24;
}

sub textbox
{
  return $_[0]->{"text"};
}

sub TIEHANDLE
{
  my $win = tied(*STDOUT);

  return new GtkTextPrinter($_[1], $win);
}

sub WRITE
{
  my $self = shift;

  $self->print("WRITE not supported...\n");
}

sub PRINT
{
  my $self = shift;
  my $var;

  foreach $var (@_)
    { $self->print($var); }
}

sub PRINTF
{
  my $self = shift;

  $self->print("PRINTF not supported...\n");
}

sub READ
{
  my $self = shift;

  $self->print("On STDIN?  Nuhuh...\n");
}

sub READLINE
{
  my $self = shift;

  $self->print("On STDIN?  Nuhuh...\n");
}

sub GETC
{
  my $self = shift;

  $self->print("On STDOUT?  Nuhuh...\n");
}

sub CLOSE
{
  my $self = shift;
  
  $self->print("CLOSE not supported...\n");
}

sub DESTROY
{
}

1;

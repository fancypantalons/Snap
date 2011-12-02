package TkTextPrinter;

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

  my $i;

  $colours[0] = "black";
  $colours[1] = "dark grey";
  $colours[2] = "light grey";
  $colours[3] = "dark blue";
  $colours[4] = "green";
  $colours[5] = "red";
  $colours[6] = "magenta";
  $colours[7] = "purple";
  $colours[8] = "orange";
  $colours[9] = "yellow";
  $colours[10] = "green";
  $colours[11] = "dark green";
  $colours[12] = "cyan";
  $colours[13] = "blue";
  $colours[14] = "pink";
  $colours[15] = "white";

  for ($i = 0; $i < 15; $i++)
    {
      $self->{"text"}->Tag("colour_$i", -foreground => $colours[$i]);
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
  my $colour = $self->{"last_colour"};
  my $textbox = $self->{"text"}; 

  while ($line =~ /(.*?)~(\d{1,2}|c);/gc)
    {
      my $text = $1;
      my $nextcolour = $2;

      $nextcolour = 1 if ($nextcolour eq "c");
      $nextcolour = 15 if ($nextcolour > 15);      
      
      $textbox->insert("end", $text, [ "colour_$colour" ]);
     
      $colour = $nextcolour;
    } 

  $textbox->insert("end", substr($line, pos($line)), [ "colour_$colour" ]);
  $textbox->see("end");

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

  return new TkTextPrinter($_[1], $win);
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

package StdWindow;

use FileHandle;

sub new
{
  my $class = shift;
  my $handle = shift;
  my $self = {};
  my ($width, $height);

  bless($self, $class);
  $self->{"handle"} = $handle;
  $self->{"oldwin"} = shift;

  return $self;
}

sub redraw
{
}

sub clear
{
}

sub print
{
  my ($self, $text) = @_;

  $self->{"oldwin"}->print($text) if (defined $self->{"oldwin"});

  $text =~ s/~.*?;//g;

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

      $self->{"buffer"} .= $line;

      if ($line =~ /\n/)
        {
	  my $buf = $self->{"buffer"};
	  my $handle = $self->{"handle"};

	  print $handle $buf;
	  $self->{"buffer"} = "";
	};
    }
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
  return -1;
}

sub TIEHANDLE
{
  my $class = shift;
  my $obj = shift;

  return $obj;
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

  $self->print("On STDIN?  Nuhuh...\n");
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

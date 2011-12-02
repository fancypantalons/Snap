package SnapLib::StdWindow;

sub new
{
  my $class = shift;
  my $handle = shift;
  my $self = {};
  my ($width, $height);

  bless($self, $class);
  $self->{"handle"} = $handle;

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
  my $self = shift;
  my $text = shift;
  my $handle = $self->{"handle"};

  $text =~ s/~.*?;//g;

  print $handle $text;
}

sub page_up
{
}

sub page_down
{
}

sub width
{
  return $ENV{COLUMNS};
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

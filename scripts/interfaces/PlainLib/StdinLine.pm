package StdinLine;

$TRUE = 1;
$FALSE = 0;

sub new
{
  my $class = shift;
  my $self = {};
  my ($width, $height);

  bless($self, $class);
  $self->{"status"} = 0;
  $self->{"line"} = "";

  return $self;
}

sub getchar
{
  my $self = shift;

  $self->{"line"} = <>;
  chomp($self->{"line"});

  $self->{"status"} = $TRUE;
}

sub line_available
{
  my $self = shift;

  return $self->{"status"};
}

sub getline
{
  my $self = shift;

  return $self->{"line"};
}

1;

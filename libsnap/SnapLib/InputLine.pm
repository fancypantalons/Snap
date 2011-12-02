package SnapLib::InputLine;

use Curses;

$TRUE = 1;
$FALSE = 0;

sub new
{
  my $class = shift;
  my $self = {};
  my ($width, $height);

  bless($self, $class);
  $self->{"window"} = shift;
  $self->{"status"} = $FALSE;
  $self->{"start"} = 0;
  $self->{"pos"} = 0;
  $self->{"length"} = 0;
  $self->{"history"} = [""];
  $self->{"oldhist"} = [""];
  $self->{"histpos"} = 0;
  $self->{"line"} = "";

  $self->{"keys"} = 
      {"\n" => \&key_newline,
       &KEY_BACKSPACE => \&key_backspace,
       chr(127) => \&key_backspace,
       chr(4) => \&key_delete,
       chr(11) => \&key_kill_line,
       &KEY_UP => \&key_up,
       &KEY_DOWN => \&key_down,
       &KEY_LEFT => \&key_left,
       &KEY_RIGHT => \&key_right,
       chr(1) => \&key_home,
       chr(5) => \&key_end,
       &KEY_NPAGE => \&key_page_down,
       &KEY_PPAGE => \&key_page_up};

  getmaxyx($self->{"window"}, $height, $width);

  $self->{"width"} = $width;

  keypad($self->{"window"}, 1);
  nodelay($self->{"window"}, 1);
  intrflush($self->{"window"}, 1);

  return $self;
}

sub key_newline
{
  my $self = shift;
  my $history = $self->{"history"};
  my $oldhist = $self->{"oldhist"};
  my $histlen = $#$history;

  $self->{"status"} = $TRUE;
  $self->{"pos"} = 0;
  $self->{"length"} = 0;
  $self->{"start"} = 0;
  $self->{"line"} = $history->[$self->{"histpos"}];

  $history->[$histlen] = $history->[$self->{"histpos"}];
  $oldhist->[$histlen] = $history->[$self->{"histpos"}];
  $history->[$histlen + 1] = "";

  $history->[$self->{"histpos"}] = $oldhist->[$self->{"histpos"}];

  $self->{"histpos"} = $#$history;
}

sub key_up
{
  my $self = shift;
  my $history = $self->{"history"};

  return if ($self->{"histpos"} <= 0);

  $self->{"histpos"}--;
  $self->{"length"} = length($history->[$self->{"histpos"}]);
  $self->{"pos"} = $self->{"length"};

  if (($self->{"pos"} - $self->{"start"} >= $self->{"width"}) ||
      ($self->{"pos"} - $self->{"start"} < 0))
    {
      $self->{"start"} = $self->{"pos"} - round_up($self->{"width"}/2);
      $self->{"start"} = 0 if ($self->{"start"} < 0);
    }
}

sub key_down
{
  my $self = shift;
  my $history = $self->{"history"};

  return if ($self->{"histpos"} >= $#$history);

  $self->{"histpos"}++;
  $self->{"length"} = length($history->[$self->{"histpos"}]);
  $self->{"pos"} = $self->{"length"};

  if (($self->{"pos"} - $self->{"start"} >= $self->{"width"}) ||
      ($self->{"pos"} - $self->{"start"} < 0))
    {
      $self->{"start"} = $self->{"pos"} - round_up($self->{"width"}/2);
      $self->{"start"} = 0 if ($self->{"start"} < 0);
    }
}

sub key_left
{
  my $self = shift;

  $self->{"pos"}-- if ($self->{"pos"} > 0);
}

sub key_right
{
  my $self = shift;

  $self->{"pos"}++ if ($self->{"pos"} < $self->{"length"}); 
}

sub key_home
{
  my $self = shift;

  $self->{"pos"} = 0;
}

sub key_end
{
  my $self = shift;

  $self->{"pos"} = $self->{"length"};
}

sub key_kill_line
{
  my $self = shift;
  my $buf = $self->{"history"}->[$self->{"histpos"}];

  $buf = substr($buf, 0, $self->{"pos"});

  $self->{"history"}->[$self->{"histpos"}] = $buf;
  $self->{"length"} = length($buf);
}

sub key_page_up
{
  my $self = shift;

  $self->set_line("/pageup");
}

sub key_page_down
{
  my $self = shift;

  $self->set_line("/pagedown");
}

sub key_backspace
{
  my $self = shift;
  my $buf = $self->{"history"}->[$self->{"histpos"}];

  return if (($self->{"length"} == 0) || ($self->{"pos"} == 0));  
  
  $buf = substr($buf, 0, $self->{"pos"} - 1) . 
         substr($buf, $self->{"pos"});

  $self->{"history"}->[$self->{"histpos"}] = $buf;

  $self->{"length"}--;
  $self->{"pos"}--;
}

sub key_delete
{
  my $self = shift;
  my $buf = $self->{"history"}->[$self->{"histpos"}];

  return if (($self->{"length"} == 0) || 
	     ($self->{"pos"} == $self->{"length"}));  
  
  $buf = substr($buf, 0, $self->{"pos"}) . 
         substr($buf, $self->{"pos"} + 1);

  $self->{"history"}->[$self->{"histpos"}] = $buf;
  $self->{"length"}--;
}

sub round_up
{
  my $val = shift;
  my $intval = int($val);

  if ($val - $intval >= 0.5)
    {
      $intval++;
    }

  return $intval;
}

sub addchar
{
  my $self = shift;
  my $ch = shift;

  my $window = $self->{"window"};

  if (defined $self->{"keys"}->{$ch})
    {
      &{ $self->{"keys"}->{$ch} }($self);
    }
  else
    {
      my $buf = $self->{"history"}->[$self->{"histpos"}];

      $buf = substr($buf, 0, $self->{"pos"}) . $ch . 
  	     substr($buf, $self->{"pos"});

      $self->{"history"}->[$self->{"histpos"}] = $buf;

      $self->{"pos"}++;
      $self->{"length"}++;
    }

  if (($self->{"pos"} - $self->{"start"} >= $self->{"width"}) ||
      ($self->{"pos"} - $self->{"start"} < 0))
    {
      $self->{"start"} = $self->{"pos"} - round_up($self->{"width"}/2);
      $self->{"start"} = 0 if ($self->{"start"} < 0);
    }

  $self->redraw;
}

sub getchar
{
  my $self = shift;
  my $ch;

  if (($ch = getch($self->{"window"})) != ERR)
    { $self->addchar($ch); }
}

sub redraw
{
  my $self = shift;
  my $window = $self->{"window"};  
  my $line;
  my $cursor_pos = $self->{"pos"} - $self->{"start"};
  my $buf = $self->{"history"}->[$self->{"histpos"}];

  $line = substr($buf, $self->{"start"}, $self->{"width"});
  $line .= " " x ($self->{"width"} - $cursor_pos);

  addstr($window, 1, 0, $line); 
  move($window, 1, $cursor_pos);  

  refresh($window);
}

sub line_available
{
  my $self = shift;

  return $self->{"status"};
}

sub getline
{
  my $self = shift;

  $self->{"status"} = $FALSE;
  return $self->{"line"};
}

sub set_key
{
  my ($self, $key, $sub) = @_;

  $self->{"keys"}->{$key} = $sub;
}

sub set_line
{
  my ($self, $line) = @_;

  $self->{"line"} = $line;
  $self->{"status"} = $TRUE;
}

1;

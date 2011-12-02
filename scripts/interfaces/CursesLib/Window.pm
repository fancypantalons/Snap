package Window;

use Curses;

sub new
{
  my $class = shift;
  my $self = {};
  my ($width, $height);

  bless($self, $class);
  $self->{"window"} = shift;
  $self->{"scrollback"} = shift;
  $self->{"oldwin"} = shift;
  $self->{"top"} = 0;
  $self->{"buffer"} = [];
  $self->{"length"} = 0;
  $self->{"dirty"} = 0;

  getmaxyx($self->{"window"}, $height, $width);
  scrollok($self->{"window"}, 0);

  $self->{"width"} = $width;
  $self->{"height"} = $height;

  return $self;
}

sub redraw
{
  my $self = shift;
  my $window = $self->{"window"};
  my $i;
  my $end = $self->{"top"} + $self->{"height"};
  my ($cury, $curx);
  my $colour = undef;

  return if (! $self->{"dirty"});

  erase($window);
  move($window, 0, 0);
  attrset($window, COLOR_PAIR(1));  # Set default colour...

  for ($i = $self->{"top"}; $i < $end; $i++)
    {
      my $line = $self->{"buffer"}->[$i];
      my $text;

      chomp($line);

      while ($line =~ /~(\d{1,2}|c);/)
        {
	  $nextcolour = $1;
	  $text = $line;
	  
	  $line =~ s/^.*?~\Q$nextcolour\E;//;
	  $text =~ s/~\Q$nextcolour;$line\E$//;
	  
	  if ($nextcolour eq "c") { $nextcolour = 1; }
	  
	  attrset($window, COLOR_PAIR($colour));
	  addstr($window, $text);

	  $colour = $nextcolour;
	  
	  if ($colour > 15) { $colour = 15; }
        }  

      attrset($window, COLOR_PAIR($colour)) if (defined $colour);
      addstr($window, $line);
      addstr($window, "\n");
    }

  refresh($window);

  $self->{"dirty"} = 0;
}

sub clear
{
  my $self = shift;
  my $window = $self->{"window"};

  splice @{ $self->{"buffer"} }, 0;
  $self->{"length"} = 0;
  $self->{"top"} = 0;
  $self->{"dirty"} = 1;

  $self->redraw();
}

sub actual_len
{
  my $text = shift;
  my $temp = $text;

  $temp =~ s/~.*?;//g;

  return length($text) - length($temp);
}

sub display_pos
{
  my ($text, $disp_pos) = @_;
  my ($i, $pos) = (0, 0);

  while (($i < length($text)) && ($pos < $disp_pos))
    {
      if (substr($text, $i, 1) eq "~")
        { 
	  while (substr($text, $i, 1) ne ";") { $i++ } 
	  $i++;
        }
      else
        {
	  $i++;
	  $pos++;
        }
    }

  return $i;
}

sub print
{
  my $self = shift;
  my $text = shift;

  my $window = $self->{"window"};
  my $i;

  $self->{"oldwin"}->print($text) if (defined $self->{"oldwin"});

  while ($text ne "")
    {
      # Do the word-wrapping line-breaking stuff...
      # Yucky code?  I think so! :)
      
      if (((index($text, "\n") < 0) && (actual_len($text) > $self->{"width"} - 1)) ||
          (index($text, "\n") - actual_len(substr($text, 0, index($text, "\n"))) > $self->{"width"} - 1))
        {
	  $text = substr($text, 0, display_pos($text, $self->{"width"} - 1)) . "\n" .
   	          substr($text, display_pos($text, $self->{"width"} - 1));
        }   

      # Now the guts...

      my $line;
      my $pos = index($text, "\n") + 1;

      if ($pos > 0)
        { $line = substr($text, 0, $pos); }
      else
        { $line = $text; }

      $text =~ s/^\Q$line\E//;

      $self->{"buffer"}->[$self->{"length"}] .= $line;

      if ($self->{"length"} > $self->{"scrollback"})
        {
          shift @{ $self->{"buffer"} };
          $self->{"length"}--;
        }

      $self->{"length"}++ if ($line =~ /\n/);

      next if ($daemon);

      if ($self->{"length"} - $self->{"top"} > $self->{"height"} - 1)
        { $self->{"top"}++; }

      $self->{"dirty"} = 1;
    }

  $self->redraw() if ($self->{"dirty"});
}

sub page_up
{
  my $self = shift;
  my $window = $self->{"window"};

  $self->{"top"} -= $self->{"height"} / 2;
  $self->{"top"} = 0 if ($self->{"top"} < 0);

  $self->{"dirty"} = 1;
  $self->redraw();
}

sub page_down
{
  my $self = shift;
  my $window = $self->{"window"};

  $self->{"top"} += $self->{"height"} / 2;

  if ($self->{"length"} - $self->{"top"} + 1 < $self->{"height"})
    { $self->{"top"} = $self->{"length"} - $self->{"height"} + 1; }

  $self->{"top"} = 0 if ($self->{"top"} < 0);
  $self->{"dirty"} = 1;

  $self->redraw();
}

sub width
{
  my $self = shift;

  return $self->{"width"};
}

sub height
{
  my $self = shift;

  return $self->{"height"};
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

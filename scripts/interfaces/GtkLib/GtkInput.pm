package GtkInput;

@ISA = qw(Gtk::Entry);

sub new
{
  my $class = shift;
  my $self = Gtk::Entry->new();

  bless $self, $class;

  $self->signal_connect("activate", \&enter_handler);
  $self->signal_connect_after("key_press_event", \&key_handler);
  $self->{"history"} = [""];
  $self->{"oldhist"} = [""];
  $self->{"histpos"} = 0;

  return $self;
}

sub key_handler
{
  my $self = shift;
  my $e = shift;
  my $key = $e->{'keyval'};
  my $history = $self->{"history"};
  my $oldhist = $self->{"oldhist"};
  my $histpos = $self->{"histpos"};

  if ($key == $Gtk::Keysyms{'Up'})
    {
      $history->[$self->{"histpos"}] = $self->get_text();
      $self->{"histpos"}-- if ($self->{"histpos"} > 0);
      $self->set_text($history->[$self->{"histpos"}]);
    }
  elsif ($key == $Gtk::Keysyms{'Down'})
    {
      $history->[$self->{"histpos"}] = $self->get_text();
      $self->{"histpos"}++ if ($self->{"histpos"} < $#$history);
      $self->set_text($history->[$self->{"histpos"}]);
    }

  $self->signal_emit_stop_by_name("key_press_event");

  return 1;
}

sub enter_handler
{
  my $self = shift;
  my $history = $self->{"history"};
  my $oldhist = $self->{"oldhist"};
  my $histpos = $self->{"histpos"};
  my $histlen = $#$history;

  $history->[$histpos] = $oldhist->[$histpos];
  $history->[$histlen] = $self->get_text();
  $oldhist->[$histlen] = $self->get_text();
  $history->[$histlen + 1] = "";
  $self->{"histpos"} = $#$history;

  $self->set_text("");
}

sub getline
{
  my $history = $_[0]->{"history"};
  return $history->[$#$history - 1];
}

1;

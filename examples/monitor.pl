$VERSION = "0.01";

print_to_window("Monitor $VERSION Loaded...\n");

push @extensions, "Monitor";

sub do_monitor()
{
  my ($sock, $text, $textwin, $text_state, $cmdwin, $line_state) = @_;
  my $dl = $downloads[0];

  if (defined $dl)
    {
      addstr ($cmdwin, 0, 60, $$dl{"received"} . ":" . $$dl{"size"});
      touchwin stdscr; refresh($cmdwin);
    }
}

push @{ $code_hash{&MSG_RECV_DL_BLOCK} }, \&do_monitor;

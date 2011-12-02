$VERSION = "0.01";

$textwin->print("Monitor $VERSION Loaded...\n", 2);

push @extensions, "Monitor";

sub do_monitor()
{
  my ($sock, $text, $textwin, $cmdwin) = @_;
  my $dl = $downloads[0];

  if (defined $dl)
    {
      addstr ($cmdwin->{"window"}, 0, 60, $$dl{"received"} . ":" . $$dl{"size"});
    }
}

push @{ $code_hash{&MSG_RECV_DL_BLOCK} }, \&do_monitor;

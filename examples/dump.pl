sub do_dump
{
  my ($sock, $textwin, $text_status, $cmdwin, $cmd_status, $param_str, @params) = @_;
  my @lines = @{ $$text_status{"buffer"} };
  my $line;
  my $outfile = new FileHandle ">screen.txt";

  foreach $line (@lines)
    {
      print $outfile "> $line";
    }

  $outfile->close();
}

$command_hash{"/dump"} = [\&do_dump];

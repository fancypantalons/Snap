sub do_logcheck
{
  my ($sock, $param_str, @params) = @_;
  my $count = shift @params;
  my $logf = new FileHandle "<$logname";
  my @lines = <$logf>;
  my $i;
  my $title = "Log Output";

  $title .= "\n" . "-" x length($title) . "\n";

  $logf->close();

  print $title;

  my ($start, $end);

  if ($count < 0)
    {
      $start = $#lines + $count + 1;
      $end = $#lines + 1;
    }
  else
    {
      $start = 0;
      $end = $count;
    }

  for ($i = $start; $i < $end; $i++)
    {
      print "$lines[$i]";
    }

  print "\n";
}

$command_hash{"/logcheck"} = [\&do_logcheck];
$help_hash{"/logcheck"} = "Usage: /logcheck [n]\n\n  Prints the last <n> lines of the log file.\n\n";

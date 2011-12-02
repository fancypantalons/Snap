sub do_bgrep
{
  my ($sock, $textwin, $text_status, $cmdwin, $cmd_status, $param_str, @params) = @_;
  my @lines = @{ $$text_status{"buffer"} };
  my $line;
  my $title = "Backward Grep Results";

  $title .= "\n" . "-" x length($title) . "\n";
  print_to_window($textwin, $title, $text_status, 1);

  foreach $line (@lines)
    {
      if ($line =~ /$param_str/)
        {
          print_to_window($textwin, $line, $text_status, 1);
        }
    }
}

$command_hash{"/bgrep"} = [\&do_bgrep];

$help_hash{"/bgrep"} = 
"Usage: /bgrep <regex>

  Searches the scrollback buffer for a given string matching
  the expressions <regex>.

";

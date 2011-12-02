package SnapLib::Debug;

use POSIX qw(strftime);

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(debug_init debug_print);

my $logfile;
my @catagories;

sub add_debug_catagory
{
  push @catagories, $_[0];
}

sub debug_init
{
  my $logname = shift;

  return if ($logname eq "");

  $logfile = new FileHandle ">$logname";
  $logfile->autoflush();  
}

sub debug_print
{
  my $catagory = shift;
  my $text = shift;
  my $date = strftime "%b %e %H:%M:%S", localtime;

  if ((! grep {/^\Q$catagory\E$/i} @catagories) &&
      (! grep {/^all$/} @catagories))
    { return; }

  if (defined $logfile)
    { print $logfile "$date $catagory: $text"; }
}

1;

package SnapLib::Debug;

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(debug_init debug_print);

my $logfile;

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

  if (defined $logfile)
    { print $logfile "$catagory: $text"; }
}

1;

#
# Generic file scrambling framework scripts.  See pig_latin.pl for an example
# for how to encode shared file names.
#

my $ENCODE_SUB = sub { return $_[0]; };
my $VERSION = "0.01";

$ENCODER_LOADED = 1;

push @{ $code_hash{&MSG_INIT} }, \&encode_list;

print "File Encoder Module $VERSION loaded...\n";

sub encode_list
{
  my ($sock, $text) = @_;
  my $file;

  foreach $file (sort keys %$cache)
    {
      next if ($file eq "");

      my $mangled_name = $file;

      $mangled_name =~ s/^\Q$upload\E\/?//g;
      $mangled_name =~ s/\.mp3$//;
      $mangled_name = $ENCODE_SUB->($mangled_name);

      $$cache{$file}{name} = $mangled_name . ".mp3";
    }  
}

sub set_encoder
{
  $ENCODE_SUB = $_[0];
}

sub encode
{
  return $ENCODE_SUB->($_[0]);
}

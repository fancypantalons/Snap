#
# Example filename encoder, using a basic pig latin mangle.
#

if (! defined $ENCODER_LOADED) { eval_file("encode.pl"); }

my $VERSION = "0.01";

set_encoder(\&pig_latinize);

print "Pig Latin Encoder $VERSION loaded...\n";

sub pig_latinize
{
  my $filename = shift;

# Now, split it according to _, -, and spaces.

  my @parts = split(/[ _-]/, $filename);

# Once splitted, take each word and move the first character to the end.

  foreach (@parts)
    {
      $_ =~ s/(.)(.*)/$2$1/;
    }

# And return a version of the name joined with _'s.

  return (join(" ", @parts));
}

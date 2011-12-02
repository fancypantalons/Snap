#
# This package defines a generic wrapper for the %handles hash, which 
# scripts can use to wrap Snap in another event loop.  The object is used
# by tying the %handles hash to 'HandleWrapper', and providing two function
# references, the first is a store function, the second a delete function.
# These functions should add or remove handles from the wrapping event loop.
#
# See the GtkImport.pl and TkImport.pl scripts for examples on how to use
# this module.
#

package HandleWrapper;

require Tie::Hash;
use SnapLib::Debug;
use Data::Dumper;

@ISA = qw(Tie::StdHash);

sub TIEHASH
{
  my ($class, $store, $delete) = @_;
  my $self = bless {}, $class;

  $self->{'store'} = $store;
  $self->{'delete'} = $delete;

  return $self;
}

sub STORE
{
  my ($self, $key, $value) = @_;
  my %data;

  debug_print("Handles", "Adding $key => $value\n");

  $data{Handle} = $value->{Handle};
  $data{Callback} = $value->{Callback};

  $self->{'store'}->(\%data);

  $self->SUPER::STORE($key, \%data);
}

sub DELETE
{
  my ($self, $key) = @_;
  my $data = $self->SUPER::FETCH($key);

  if (! defined $data)
    {
      debug_print("Handles", "Error deleting: key not found!\n");
      return;
    }

  debug_print("Handles", "Removing $key\n");

  $self->SUPER::DELETE($key);

  $self->{'delete'}->($data);
}

1;

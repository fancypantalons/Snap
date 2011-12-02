package SnapLib::Download;

use IO::Socket;
use IO::Select;
use SnapLib::Debug;
use POSIX qw(_exit);

sub new
{
  my $class = shift;
  my ($socket, $file, $filename, $sentname, $size) = @_;
  my $self = {};
  my $pid;

  bless $self, $class;

  my ($read_child, $write_parent) = (new FileHandle, new FileHandle);
  my ($read_parent, $write_child) = (new FileHandle, new FileHandle);

  pipe $read_child, $write_parent;
  pipe $read_parent, $write_child;

  $write_parent->autoflush(1);
  $write_child->autoflush(1);

  if (($pid = fork()) != 0)
    {
      $self->{"read"} = $read_parent;
      $self->{"write"} = $write_parent;
      $self->{"pid"} = $pid;
      $self->{"filename"} = $filename;
      $self->{"sentname"} = $sentname;
      $self->{"size"} = $size;

      return $self;
    }

  $self->{"socket"} = $socket;
  $self->{"file"} = $file;

  die "$!\n" if ($pid eq undef); 

  $SIG{INT} = sub {
    $self->{"socket"}->close();
    $self->{"file"}->close();
    debug_print("DL", "Child dying off...\n");
    _exit(0);
  };

  my $s = new IO::Select;
  $s->add($read_child, $self->{"socket"});

  my $old_time = 0;

  $self->{"time"} = time();

  while (1)
    {
      my @ready = $s->can_read(1);
      my $fh;
      my $cur_time = time();

      if ($#ready >= 0)
        {
          $len = $self->{"socket"}->sysread($rcv, 1024);
          
          next if (! defined $len);           
          
          if ($len != 0)
            {
              $self->{"received"} += $len;
              $self->{"file"}->print($rcv);

              if (($cur_time - $old_time) >= 1)
                {
                  print $write_child "LENGTH $self->{received}\n";
                }              
            }
          else
            {
              $self->{"socket"}->close();
              $self->{"file"}->close();
              splice(@downloads, $i, 1);
              print $write_child "PRINT Finished transferring $self->{name}..\n";
              debug_print("DL", "Finished transferring $self->{localname} (got $self->{received})...\n");
              _exit(0);
            }
        }

      if ((($cur_time - $self->{"time"} > 0) &&
          (($cur_time - $old_time) >= 1)) || 
	  ($#ready < 0))
        {
	  $self->{"speed"} = sprintf "%.2f", (($self->{"received"} / ($cur_time - $self->{"time"})) / 1000);

          print $write_child "SPEED $self->{speed}\n";
        }

      $old_time = $cur_time;
    }
}

1;

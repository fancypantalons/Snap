package SnapLib::Upload;

use IO::Socket;
use IO::Select;
use SnapLib::Debug;
use POSIX qw(_exit);

use constant UL_BLOCK_LEN => 2048;

sub new
{
  my $class = shift;
  my $self = shift;

  my $socket = $self->{"socket"};
  my $file = $self->{"file"};
  my $filename = $self->{"filename"};
  my $size = $self->{"size"};
  my $pos = $self->{"pos"};
  my $user = $self->{"user"};
  my $limit = $self->{"limit"};

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

      return $self;
    }

  $self->{"socket"} = $socket;
  $self->{"file"} = $file;
  $self->{"pos"} = $pos;
  $self->{"filename"} = $filename;
  $self->{"user"} = $user;
  $self->{"limit"} = $limit;

  die "$!\n" if ($pid eq undef); 

  $SIG{INT} = sub {
    $self->{"socket"}->close();
    $self->{"file"}->close();
    debug_print("UL", "Child dying off...\n");
    _exit(0);
  };

#  $SIG{__DIE__} = sub {
#      debug_print("UL", "Error: $!\n");
#      _exit(0);
#  };

  my $s1 = new IO::Select;
  my $s2 = new IO::Select;
  my @ready;  

  $s1->add($self->{"socket"});
  $s2->add($read_child);

  if ($self->{"pos"} > 0)
    {
      seek $self->{"file"}, $self->{"pos"}, 0;
      $self->{"pos"} = 0;
    }      

  my ($oldt, $curt, $start) = (time(), 0, time());

  while (1)
    {
      @ready = IO::Select->select($s2, $s1, undef, 1);

      $curt = time();

      if ((($curt - $oldt) >= 1) || ($#ready < 0))
        {
          my $speed = sprintf "%.2f", (($self->{"sent"} / ($curt - $start)) / 1000); 
          print $write_child "SPEED $speed\n";
	  print $write_child "LENGTH $self->{sent}\n";

	  $oldt = $curt;
        }
                
      next if (($#ready < 0) || ($#{ $ready[1] } < 0));

      if ($#{ $ready[0] } >= 0)
        {
          my $line = <$read_child>;
          
          $line =~ /(.+?) (.*)/;
          
          if ($1 eq "LIMIT")
            {
              $self->{"limit"} = $2;
              
              print $write_child "PRINT Setting speed limit to $self->{limit}...\n";
            }
        }
      
      if (defined &Time::HiRes::gettimeofday)
        {            
           my $cur_time = Time::HiRes::gettimeofday();

	   if (! defined $self->{"last_time"})
  	     { $self->{"last_time"} = $cur_time; }
          
           my $len = UL_BLOCK_LEN / $self->{"limit"} if ($self->{"limit"} > 0);
           my $span = $cur_time - $self->{"last_time"};

           if (($self->{"limit"} > 0) &&
               ($len > $span))
             { Time::HiRes::sleep($len - $span); }

	   $self->{"last_time"} = Time::HiRes::gettimeofday();
        }
      
      my $datablock;
      my $datasize = sysread($self->{"file"}, $datablock, UL_BLOCK_LEN);
      my $error = 0;

      if ($datasize > 0)
        {
          my $sent_amt;

          $SIG{PIPE} = sub {
            $error = 1;
            return;
          };
          
          $sent_amt = $self->{"socket"}->syswrite($datablock, $datasize);

          if (! $error)
            {
              $self->{"sent"} += $sent_amt;
              $self->{"len_sample"} += $sent_amt;

              next;
            }
        }
      
      if ($error)
        {
          debug_print("UL", "Upload to $self->{user} terminated abnormally...\n");
          print $write_child "PRINT Upload to $self->{user} terminated abnormally...\n";
        }
      
      $self->{"socket"}->close();
      $self->{"file"}->close();
      splice(@uploads, $up_num, 1);
      
      debug_print("UL", "Upload to $self->{user} of $self->{filename} terminating (sent $self->{sent})...\n");
      print $write_child "PRINT Upload to $self->{user} of $self->{filename} terminating...\n";
      _exit(0);
    }
}

1;

#
# This module implements a Gtk-based GUI for Snap.  This module MUST
# be loaded on startup.  To load the module, add this line to your
# snaprc:
#
# eval_file('Gtk.pl');
#
# Or, run snap like this:
#
# snap -f Gtk.pl
#
# This module makes use of the GtkImport module to load the actual
# Gtk library and to wrap the event loop.  If GtkImport is not loaded,
# it tries to load it itself and returns an error on failure.
#

my $VERSION = "0.04";

BEGIN
{
  if ((defined $INTERFACE) || ($daemon)) { $SUCCESS = 0; return 1; }

  foreach (@SCRIPT_PATH)
    {
      push @INC, "$_/GtkLib";
    }

  if (! $GTK_ENABLED)
    {
      eval_file("GtkImport.pl");
    }

  my $oh = $SIG{__DIE__};

  $SIG{__DIE__} = sub { return; };

  eval
    {
      require GtkTextPrinter;
      import GtkTextPrinter;

      require GtkInput;
      import GtkInput;

      require SnapLib::MessageTypes;
      import SnapLib::MessageTypes;
    };

  $SIG{__DIE__} = $oh;

  if ($@)
    {
      print "Error, unable to load Gtk module...\n";

      $SUCCESS = 0;

      return 1;
    }
  else
    {
      $SUCCESS = 1;
    }
}

return if (! $SUCCESS);
      
if (! $GTK_ENABLED)
{
  print "Gtk Import Module not loaded!\n";
  return 1;
}

$INTERFACE = 1;

push @extensions, "GtkGUI";
print "Gtk GUI Module $VERSION Loaded...\n";

push @{ $code_hash{&MSG_INIT} }, \&setup_gui;

%GUI;

sub setup_gui
{
  my $func;
  my ($textbox, $win, $scroller, $hbox, $vbox, $input, $style);
  my $notebook;
  my $subfactory;
  my $accel_group;

  ########################### Main Window Code ################################

  $win = Gtk::Window->new();
  $win->set_default_size(600, 450);
  $win->set_title("Snap $CLIENT_VERSION");

  $vbox = Gtk::VBox->new(0, 0);
  $win->add($vbox);
  $vbox->show();

  $accel_group = new Gtk::AccelGroup;
  $accel_group->attach($win);
  $menu_factory = Gtk::ItemFactory->new('Gtk::MenuBar', "<main>", $accel_group);
  $vbox->pack_start($menu_factory->get_widget("<main>"), 0, 0, 0);

  $menu_factory->create_item({ path => '/File/Quit',
			       accelerator => '<control>Q',
			       type => '<Item>'}, sub { shutdown_prog($napster_sock) } );

  $menu_factory->create_item({ path => '/Plugins',
			       type => '<Branch>' }, sub {});
  
  $menu_factory->create_item({ path => '/Help',
			       type => '<LastBranch>' }, sub {});

  $menu_factory->create_item({ path => '/Help/Command Index',
			       type => '<Item>' }, \&gtk_help );

  $menu_factory->get_widget("<main>")->show_all();

  $notebook = new Gtk::Notebook;
  $notebook->set_tab_pos(-top);
  $vbox->pack_start($notebook, 1, 1, 0);
  $notebook->show();

  $input = GtkInput->new();
  $vbox->pack_start($input, 0, 0, 0);
  $input->show;
  
  $statusbar = new Gtk::Statusbar;
  $vbox->pack_start($statusbar, 0, 0, 0);
  $statusbar->show();

  $GUI{"statusbar"} = $statusbar;
  $GUI{"menu_factory"} = $menu_factory;
  $GUI{"vbox"} = $vbox;
  $GUI{"notebook"} = $notebook;

  ############################ Console Window #################################

  $hbox = Gtk::HBox->new(0, 0);
  $notebook->append_page($hbox, Gtk::Label->new("Console"));
  $hbox->show();

  $textbox = Gtk::Text->new();
  $hbox->pack_start($textbox, 1, 1, 0);
  $textbox->show();

  $style = $textbox->style->copy;
  $style->base("normal", Gtk::Gdk::Color->parse_color("black"));
  $textbox->set_style($style); 

  $scroller = Gtk::VScrollbar->new($textbox->vadj);
  $hbox->pack_start($scroller, 0, 0, 0);
  $scroller->show;

  $GUI{"textbox"} = $textbox;
  $GUI{"text_scroller"} = $scroller;
  $GUI{"console_hbox"} = $hbox;

  ################################ Search Page ################################

  my $table = Gtk::Table->new(8, 5, 0);

  $notebook->append_page($table, Gtk::Label->new("Search"));
  $table->show();

  my $scroller = Gtk::ScrolledWindow->new(undef, undef);
  my ($search_radio, $browse_radio);

  $search_radio = Gtk::RadioButton->new("Search");
  $browse_radio = Gtk::RadioButton->new("Browse", $search_radio);

  $table->attach($search_radio, 0, 1, 0, 1, 
                 ["expand", "fill"], 
                 ["fill"], 0, 0);

  $table->attach($browse_radio, 0, 1, 4, 5, 
                 ["expand", "fill"], 
                 ["fill"], 0, 0);

  $scroller->set_policy('automatic', 'automatic');
  $table->attach($scroller, 0, 5, 6, 8, ["expand", "fill"], ["expand", "fill"], 0, 0);
  
  my $clist = Gtk::CList->new_with_titles("File Name", "Size", "Kbps", "User", "Speed");

  $clist->set_column_width(0, 270);
  $clist->set_column_width(1, 45);
  $clist->set_column_width(2, 50);
  $clist->set_column_width(3, 100);
  $clist->set_column_width(4, 60);

  $clist->signal_connect("click_column", \&sort);

  $clist->set_selection_mode("multiple");

  $scroller->add($clist);

  my ($artist, $name, $regex, $bitrate, $freq, $speed);
  my ($br_type, $fr_type, $sp_type, $br_menu, $fr_menu, $sp_menu);
  my ($br_type_str, $fr_type_str, $sp_type_str, $speed_str);
  my $menu_factory;
  my @types = ("At Least", "At Best", "Equal To");

  $table->attach(Gtk::Label->new("Artist:"), 0, 1, 1, 2, ["fill"],
		 ["fill"], 5, 5);
  $table->attach(Gtk::Label->new("Name:"), 0, 1, 2, 3, ["fill"],
		 ["fill"], 5, 5);
  $table->attach(Gtk::Label->new("Regex:"), 0, 1, 3, 4, ["fill"],
		 ["fill"], 5, 5);
  $table->attach(Gtk::Label->new("Bitrate:"), 2, 3, 1, 2, ["fill"],
		 ["fill"], 5, 5);
  $table->attach(Gtk::Label->new("Frequency:"), 2, 3, 2, 3, ["fill"],
		 ["fill"], 5, 5);
  $table->attach(Gtk::Label->new("Speed:"), 2, 3, 3, 4, ["fill"],
		 ["fill"], 5, 5);

  $artist = new Gtk::Entry;
  $name = new Gtk::Entry;
  $regex = new Gtk::Entry;
  $bitrate = new Gtk::Entry;
  $freq = new Gtk::Entry;

  $speed = new Gtk::OptionMenu;
  $menu_factory = Gtk::ItemFactory->new('Gtk::Menu', "<main>", new Gtk::AccelGroup);

  my $str;
  foreach $str (sort { $a <=> $b } keys %SPEEDS)
    {
      $menu_factory->create_item({ path => "/$SPEEDS{$str}" },
                                 sub { $speed_str = "$str"; });
    }

  $speed->set_menu($menu_factory->get_widget("<main>"));

  $br_type = new Gtk::OptionMenu;
  $br_type_str = "+";

  $menu_factory = Gtk::ItemFactory->new('Gtk::Menu', "<main>", new Gtk::AccelGroup);
  $menu_factory->create_item({ path => '/At Least' }, 
			     sub { $br_type_str = '+' } );
  $menu_factory->create_item({ path => '/At Best' }, 
                             sub { $br_type_str = '-' });
  $menu_factory->create_item({ path => '/Equal To' }, 
                             sub { $br_type_str = '' });
  $br_type->set_menu($menu_factory->get_widget("<main>"));

  $fr_type = new Gtk::OptionMenu;
  $fr_type_str = "+";

  $menu_factory = Gtk::ItemFactory->new('Gtk::Menu', "<main>", new Gtk::AccelGroup);
  $menu_factory->create_item({ path => '/At Least' }, 
			     sub { $fr_type_str = '+' } );
  $menu_factory->create_item({ path => '/At Best' }, 
                             sub { $fr_type_str = '-' });
  $menu_factory->create_item({ path => '/Equal To' }, 
                             sub { $fr_type_str = '' });
  $fr_type->set_menu($menu_factory->get_widget("<main>"));

  $sp_type = new Gtk::OptionMenu;
  $sp_type_str = "+";

  $menu_factory = Gtk::ItemFactory->new('Gtk::Menu', "<main>", new Gtk::AccelGroup);
  $menu_factory->create_item({ path => '/At Least' }, 
                             sub { $sp_type_str = '+' });
  $menu_factory->create_item({ path => '/At Best' }, 
                             sub { $sp_type_str = '-' });
  $menu_factory->create_item({ path => '/Equal To' }, 
			     sub { $sp_type_str = '' } );
  $sp_type->set_menu($menu_factory->get_widget("<main>"));

  $table->attach($artist, 1, 2, 1, 2, ["expand", "fill"], 
		 ["fill"], 5, 5);
  $table->attach($name, 1, 2, 2, 3, ["expand", "fill"], 
		 ["fill"], 5, 5);
  $table->attach($regex, 1, 2, 3, 4, ["expand", "fill"], 
		 ["fill"], 5, 5);

  $table->attach($br_type, 3, 4, 1, 2, ["fill"], 
		 ["fill"], 5, 5);
  $table->attach($fr_type, 3, 4, 2, 3, ["fill"], 
		 ["fill"], 5, 5);
  $table->attach($sp_type, 3, 4, 3, 4, ["fill"], 
		 ["fill"], 5, 5);

  $table->attach($bitrate, 4, 5, 1, 2, ["expand", "fill"], 
		 ["fill"], 5, 5);
  $table->attach($freq, 4, 5, 2, 3, ["expand", "fill"], 
		 ["fill"], 5, 5);
  $table->attach($speed, 4, 5, 3, 4, ["expand", "fill"], 
		 ["fill"], 5, 5);

  my $button_label = Gtk::Label->new("Search");
  my $button = Gtk::Button->new();  

  $button->add($button_label);

  $GUI{"search_button"} = $button;

  $table->attach($button, 3, 5, 4, 5, ["shrink"], ["shrink"], 5, 5);

  my $username;

  $username = new Gtk::Entry();

  $table->attach($username, 1, 2, 4, 5, ["expand", "fill"], 
                 ["fill"], 5, 5);

  $username->set_sensitive(0);

  $button->signal_connect("clicked", sub { gtk_search($artist,
						      $name,
						      $regex,
						      $bitrate,
						      $freq,
						      $speed_str,
						      $br_type_str,
						      $fr_type_str,
						      $sp_type_str,
                                                      $username,
                                                      $button,
						      $button_label) });

  $search_radio->signal_connect("clicked", sub { gtk_search_enable(1,
                                                                   $artist,
                                                                   $name,
                                                                   $regex,
                                                                   $bitrate,
                                                                   $freq,
                                                                   $speed,
                                                                   $br_type,
                                                                   $fr_type,
                                                                   $sp_type,
                                                                   $username,
                                                                   $button_label) });

  $browse_radio->signal_connect("clicked", sub { gtk_search_enable(0,
                                                                   $artist,
                                                                   $name,
                                                                   $regex,
                                                                   $bitrate,
                                                                   $freq,
                                                                   $speed,
                                                                   $br_type,
                                                                   $fr_type,
                                                                   $sp_type,
                                                                   $username,
                                                                   $button_label) });
 
  my $hbox = new Gtk::HBox(1, 0);
  my $button;

  $table->attach($hbox, 0, 5, 8, 9, ["shrink"], ["shrink"], 5, 5);

  $button = Gtk::Button->new("Download");
  $hbox->pack_start($button, 0, 1, 5);
  $button->signal_connect("clicked", sub { gtk_download($clist) });

  $button = Gtk::Button->new("Queue");
  $hbox->pack_start($button, 0, 1, 5);
  $button->signal_connect("clicked", sub { gtk_queue($clist) });

  $code_hash{&MSG_SEARCH_END} = [ sub { gtk_search_end(@_, $GUI{"search_button"}); } ];
  $code_hash{&MSG_BROWSE_END} = [ sub { gtk_browse_end(@_, $GUI{"search_button"}); } ];
  
  $GUI{"download_button"} = $button;

  $table->show_all();

  push @{ $command_hash{"/search"} }, sub { $clist->clear(); };
  push @{ $command_hash{"/browse"} }, sub { $clist->clear(); };


  push @{ $code_hash{&MSG_SEARCH_ACK} }, sub { display_search_result(@_, $clist) };
  push @{ $code_hash{&MSG_BROWSE_ACK} }, sub { display_search_result(@_, $clist) };
  
  $GUI{"search_table"} = $table;
  $GUI{"artist_input"} = $artist;
  $GUI{"name_input"} = $name;
  $GUI{"regex_input"} = $regex;
  $GUI{"bitrate_input"} = $bitrate;
  $GUI{"freq_input"} = $freq;
  $GUI{"speed_input"} = $speed;
  $GUI{"search_list"} = $clist;
  $GUI{"search_scroller"} = $scroller;
  $GUI{"bitrate_type"} = $br_type;
  $GUI{"freq_type"} = $fr_type;
  $GUI{"speed_type"} = $sp_type;

  ############################## Downloads Page ###############################

  my $vbox = Gtk::VBox->new(0, 0);
  my $vbox2 = Gtk::VBox->new(0, 0);
  my $hbox = Gtk::HBox->new(0, 0);
  my $splitter = Gtk::VPaned->new();
  my $scroller = Gtk::ScrolledWindow->new(undef, undef);
  my $list = Gtk::CList->new_with_titles("Filename", "User");
  my $remove = Gtk::Button->new("Remove");
  my $align = Gtk::Alignment->new(0.5, 0.5, 1, 1);
  my $hbox = Gtk::HBox->new(0, 0);

  $vbox->pack_start($splitter, 1, 1, 0);    
  $splitter->add1($vbox2);

  $vbox2->pack_start($scroller, 1, 1, 0);
  $vbox2->pack_start($hbox, 0, 1, 2);
  $hbox->pack_start($align, 1, 0, 0);
  $align->add($remove);

  $scroller->set_policy('automatic', 'automatic');
  $scroller->add($list);

  $list->set_column_width(0, 470);
  $list->set_column_width(1, 70);
  $list->column_titles_passive();

  push @{ $command_hash{"/queue"} }, sub { gtk_queue_update($list) };
  push @{ $code_hash{&MSG_DL_END} }, sub { gtk_queue_update($list) };
  push @{ $code_hash{&MSG_DL_ERR} }, sub { gtk_queue_update($list) };

  $remove->signal_connect("clicked", sub { gtk_queue_remove($list) });

  my $scroller = Gtk::ScrolledWindow->new(undef, undef);
  my $list = Gtk::CList->new_with_titles("Filename", "Size", 
                                         "Received", "Status",
                                         "ETA");
  my $hbox = Gtk::HBox->new(0, 0);
  my $button = Gtk::Button->new("Kill Download");
  my $align = Gtk::Alignment->new(0.5, 0.5, 1, 1);

  $scroller->set_policy('automatic', 'automatic');

  $notebook->append_page($vbox, Gtk::Label->new("Downloads"));
  $splitter->add2($scroller);
  $scroller->add($list);

  $list->column_titles_passive();

  $list->set_column_width(0, 290);
  $list->set_column_width(1, 70);
  $list->set_column_width(2, 70);
  $list->set_column_width(3, 70);
  $list->set_column_width(4, 40);

  $vbox->pack_start($hbox, 0, 1, 2);
  $hbox->pack_start($align, 1, 0, 0);  
  $align->add($button);

  $button->signal_connect('clicked', sub { gtk_cancel_dl($list) });

  push @{ $command_hash{"/get"} }, sub { display_download($list) };
  push @{ $command_hash{"/queue"} }, sub { display_download($list) };
  push @{ $code_hash{&MSG_DL_INIT} }, sub { attach_download(@_, $list) };
  push @{ $code_hash{&MSG_DL_START} }, sub { gtk_add_dl(@_, $list) };
  push @{ $code_hash{&MSG_DL_END} }, sub { gtk_rem_dl(@_, $list) };
  push @{ $code_hash{&MSG_DL_END} }, sub { display_download($list) };
  push @{ $code_hash{&MSG_DL_ERR} }, sub { gtk_rem_dl_err(@_, $list) };
  push @{ $code_hash{&MSG_DL_ERR} }, sub { display_download($list) };

  push @{ $code_hash{&MSG_RECV_DL_BLOCK} }, sub { gtk_adjust_dl(@_, $list) };

  $vbox->show_all();

  $GUI{"download_scroller"} = $scroller;
  $GUI{"download_list"} = $list;
  $GUI{"download_cancel"} = $button;
  $GUI{"download_vbox"} = $vbox;
  $GUI{"download_hbox"} = $hbox;

  ############################## Uploads Page ###############################

  my $scroller = Gtk::ScrolledWindow->new(undef, undef);
  my $list = Gtk::CList->new_with_titles("Filename", "Size", 
                                         "Sent", "Status",
                                         "ETA");
  my $vbox = Gtk::VBox->new(0, 0);
  my $hbox = Gtk::HBox->new(0, 0);
  my $button = Gtk::Button->new("Kill Upload");
  my $align = Gtk::Alignment->new(0.5, 0.5, 1, 1);

  $scroller->set_policy('automatic', 'automatic');

  $list->column_titles_passive();

  $list->set_column_width(0, 290);
  $list->set_column_width(1, 70);
  $list->set_column_width(2, 70);
  $list->set_column_width(3, 70);
  $list->set_column_width(4, 40);

  $notebook->append_page($vbox, Gtk::Label->new("Uploads"));
  $vbox->pack_start($scroller, 1, 1, 0);
  $scroller->add($list);

  $vbox->pack_start($hbox, 0, 1, 5);
  $hbox->pack_start($align, 1, 0, 0);  
  $align->add($button);

  $button->signal_connect('clicked', sub { gtk_cancel_ul($list) });

  push @{ $code_hash{&MSG_UL_INIT} }, sub { attach_upload(@_, $list) };
  push @{ $code_hash{&MSG_UL_START} }, sub { gtk_add_ul(@_, $list) };
  push @{ $code_hash{&MSG_UL_END} }, sub { gtk_rem_ul(@_, $list) };
  push @{ $code_hash{&MSG_UL_ERR} }, sub { gtk_rem_ul_err(@_, $list) };
  
  push @{ $code_hash{&MSG_SENT_UL_BLOCK} }, sub { gtk_adjust_ul(@_, $list) };

  $vbox->show_all();

  $GUI{"upload_scroller"} = $scroller;
  $GUI{"upload_list"} = $list;
  $GUI{"upload_cancel"} = $button;
  $GUI{"upload_vbox"} = $vbox;
  $GUI{"upload_hbox"} = $hbox;

  ############################## Signal Handlers ##############################

  $input->signal_connect("activate", sub { do_command($napster_sock, $_[0]->getline()) } );
  $input->signal_connect("key_press_event", \&input_key_press);

  $win->signal_connect("destroy", sub { shutdown_prog($napster_sock); });
  $win->show();

  my $obj = tied *STDOUT;

  tie *STDOUT, 'GtkTextPrinter', $textbox;

  $win[0] = tied(*STDOUT);

  #
  # Code to tie in Snap events with GTK GUI.
  #
  
  $code_hash{&MSG_SERVER_STATS} = [ \&update_stats ];
  $code_hash{&MSG_DISCONNECT} = [ \&gtk_server_disconnect ];
}

sub input_key_press
{
  my $self = shift;
  my $e = shift;
  my $key = $e->{'keyval'};
  my $adj = $win[0]->textbox()->vadj;

  if ($key == $Gtk::Keysyms{'Page_Up'})
    {
      $adj->set_value($adj->get_value - $adj->page_size);
    }
  elsif ($key == $Gtk::Keysyms{'Page_Down'})
    {
      my $newpos = $adj->get_value + $adj->page_size;

      if ($newpos > $adj->upper - $adj->page_size)
        { $newpos = $adj->upper - $adj->page_size; }

      $adj->set_value($newpos);
    }
}

sub update_stats
{
  my ($sock, $text) = @_;

  $$text =~ /(\d+) (\d+) (\d+)/;

  $GUI{"statusbar"}->pop(1);
  $GUI{"statusbar"}->push(1, "Songs: $2   Libraries: $1   Gigs: $3");
}

sub gtk_server_disconnect
{
  print "Server disconnected!";
}

############################## Search/Browse Code #############################

sub gtk_search
{
  my ($artist, $name, $regex, $bitrate, $freq, $speed_str,
      $br_type, $fr_type, $sp_type, $username, $button, $button_label) = @_;
  my $cmd;

  if ($button_label->get() eq "Search")
    {
      $cmd = "/search ";      
      $cmd .= "-artist \"" . $artist->get_text() . "\" " if ($artist->get_text());
      $cmd .= "-name \"" . $name->get_text() . "\" " if ($name->get_text());
      $cmd .= "-regex \"" . $regex->get_text() . "\" " if ($regex->get_text());
      $cmd .= "-bitrate " . $bitrate->get_text() . $br_type . " " if ($bitrate->get_text());
      $cmd .= "-freq " . $freq->get_text() . $fr_type . " " if ($freq->get_text());
      $cmd .= "-speed " . $speed_str . $sp_type . " " if ($speed_str);
      
      chop($cmd);
    }
  else
    {
      $cmd = "/browse " . $username->get_text();
    }

  do_command($napster_sock, $cmd);
}

sub gtk_search_end
{
  my ($sock, $text, $button) = @_;

  print "Search completed...\n";
}

sub gtk_browse_end
{
  my ($sock, $text, $button) = @_;

  print "Browse completed...\n";
}

sub display_search_result
{
  my ($sock, $text, $list) = @_;
  my $row_num;
  my %song, $filename, $megs;

  $list->freeze();
  $list->clear();

  foreach (@search_results)
    {
      my %song = %$_;
      
      if ($song{"name"} =~ /(.*\/|.*\\)?(.*\.mp3)/)
        {
          $filename = $2;
        }
      else
        { $filename = $song{"name"}; }
      
      $megs = sprintf("%.2f", ($song{"size"} / 1000000));
      
      my $row = $list->append($filename, $megs . "M", 
                              $song{"bitrate"}, $song{"user"}, 
                              $SPEEDS{$song{"speed"}});
      
      $list->set_row_data($row, \$row);
    }

  $list->thaw();
}

sub sort
{
  my $clist = shift;
  my $column = shift;

  if ($column == 0)
    { sort_strings($clist, $column) }
  elsif ($column == 1)
    { sort_nums($clist, $column) }
  elsif ($column == 2)
    { sort_nums($clist, $column) }
  elsif ($column == 3)
    { sort_strings($clist, $column) }
  elsif ($column == 4)
    { sort_speeds($clist, $column) }
}

sub sort_strings
{
  my ($clist, $col) = @_;

  $clist->set_compare_func(sub { return $_[1] cmp $_[2] });
  $clist->set_sort_column($col);
  $clist->sort();
}

sub sort_nums
{
  my ($clist, $col) = @_;

  $clist->set_compare_func(sub { return -($_[1] <=> $_[2]) });
  $clist->set_sort_column($col);
  $clist->sort();
}

sub sort_speeds
{
  my ($clist, $col) = @_;

  $clist->set_compare_func(sub { return -(find_speed($_[1]) <=> 
					  find_speed($_[2])) });
  $clist->set_sort_column($col);
  $clist->sort();
}

sub find_speed
{
  my $str = shift;

  foreach (keys %SPEEDS)
    { return $_ if ($str eq $SPEEDS{$_}) }
}

sub gtk_search_enable
{
  my ($searching, $artist, $name, $regex, $bitrate, $freq, $speed,
      $br_type, $fr_type, $sp_type, $username, $button_label) = @_;

  $artist->set_sensitive($searching);
  $name->set_sensitive($searching);
  $regex->set_sensitive($searching);
  $bitrate->set_sensitive($searching);
  $freq->set_sensitive($searching);
  $speed->set_sensitive($searching);
  $br_type->set_sensitive($searching);
  $fr_type->set_sensitive($searching);
  $sp_type->set_sensitive($searching);

  $username->set_sensitive(! $searching);  

  $button_label->set_text(($searching) ? "Search" : "Browse");
}

############################ Queue Handling Code ##############################

sub gtk_queue_update
{
  my $list = shift;
  my $i;

  $list->freeze();
  $list->clear();

  for ($i = 0; $i <= $#download_queue; $i++)
    {
      $list->append($download_queue[$i]->{"name"}, 
                    $download_queue[$i]->{"user"});
    }  

  $list->thaw();
}

sub gtk_queue_remove
{
  my $list = shift;

  foreach ($list->selection)
    {
      do_command($napster_sock, "/queue -del " . ($_ + 1));
    }
}

########################## Download Initiation Code ###########################

sub gtk_download
{
  my $clist = shift;
  my $cmd = "/get ";

  foreach ($clist->selection)
    {
      $cmd .= (${ $clist->get_row_data($_) } + 1) . ",";
    }

  chop($cmd);
  do_command($napster_sock, $cmd);

  $clist->unselect_all();
}

sub gtk_queue
{
  my $clist = shift;
  my $cmd = "/queue -add ";

  foreach ($clist->selection)
    {
      $cmd .= (${ $clist->get_row_data($_) } + 1) . ",";
    }

  chop($cmd);
  do_command($napster_sock, $cmd);

  $clist->unselect_all();
}

########################### Download Handler Code #############################

sub display_download
{
  my $list = shift;

  $list->freeze();

  foreach (@downloads)
    {
      if ($list->find_row_from_data($_) < 0)
        {
          my $rownum = $list->append($_->{"sentname"}, "", "", "Requesting", "");

          $list->set_row_data($rownum, $_);

	  debug_print("GtkDL", "Adding download for $_\n");
        }
    }

  $list->thaw();
}

sub attach_download
{
  my ($sock, $dl, $list) = @_; 
  my $rownum = $list->find_row_from_data($dl);

  $list->set_text($rownum, 1, $$dl{"size"});
  $list->set_text($rownum, 2, $$dl{"received"});
  $list->set_text($rownum, 3, "Initializing");
}

sub gtk_add_dl
{
  my ($sock, $dl, $list) = @_;
  my $rownum = $list->find_row_from_data($dl);

  $list->set_text($rownum, 1, $$dl{"size"});
  $list->set_text($rownum, 2, $$dl{"received"});
  $list->set_text($rownum, 3, "Transferring");
}

sub gtk_rem_dl
{
  my ($sock, $dl, $list) = @_;
  my $rownum = $list->find_row_from_data($dl);

  return if ($rownum < 0);

  $list->remove($rownum);
}

sub gtk_rem_dl_err
{
  my ($sock, $dl, $list) = @_;
  my $rownum = $list->find_row_from_data($dl);

  debug_print("GtkDL", "Removing download on error for $dl\n");

  return if ($rownum < 0);

  $list->remove($rownum);

  print "Error for download, terminating...\n";
}

sub gtk_adjust_dl
{
  my ($sock, $dl, $list) = @_;
  my $row = $list->find_row_from_data($dl);

  $list->set_text($row, 2, $$dl{"received"});
      
  if (defined $$dl{"speed"})
    {
      my $time = "Stalled";

      if ($$dl{"speed"} > 0)
	{
	  my $total_time = ($$dl{"size"} - $$dl{"received"}) / 
	                   ($$dl{"speed"} * 1000);

	  my $minutes = int($total_time / 60);
	  my $seconds = int($total_time - $minutes * 60);

	  $time = "$minutes:$seconds";

	  $time = "$minutes:0$seconds" if ($seconds < 10);
	}

      $list->set_text($row, 3, $$dl{"speed"} . " Kbps");
      $list->set_text($row, 4, "$time");
    }
}

sub gtk_cancel_dl
{
  my $list = shift;

  foreach ($list->selection)
    { 
#      kill_dl($napster_sock, $_);

      my $num = $_ + 1;

      do_command($napster_sock, "/dl -kill $num");
    }
}

############################# Upload Handler Code #############################

sub attach_upload
{
  my ($sock, $ul, $list) = @_; 
  my $rownum;  

  $rownum = $list->append($$ul{"filename"}, $$ul{"size"}, 
			  $$ul{"sent"}, "Initializing", "");

  $list->set_row_data($rownum, $ul);  
}

sub gtk_add_ul
{
  my ($sock, $ul, $list) = @_;
  my $rownum = $list->find_row_from_data($ul);

  $list->set_text($rownum, 1, $$ul{"size"});
  $list->set_text($rownum, 2, $$ul{"sent"});
  $list->set_text($rownum, 3, "Transferring");
}

sub gtk_rem_ul
{
  my ($sock, $ul, $list) = @_;
  my $rownum = $list->find_row_from_data($ul);

  return if ($rownum < 0);

  $list->remove($rownum);
}

sub gtk_rem_ul_err
{
  my ($sock, $ul, $list) = @_;
  my $rownum = $list->find_row_from_data($ul);

  $list->remove($rownum);

  print "Error for upload, terminating.\n";
}

sub gtk_adjust_ul
{
  my ($sock, $ul, $list) = @_;
  my $row = $list->find_row_from_data($ul);

  $list->set_text($row, 2, $$ul{"sent"});

  if (defined $$ul{"speed"})
    {
      my $time = "Stalled";

      if ($$ul{"speed"} > 0)
	{
	  my $total_time = ($$ul{"size"} - $$ul{"sent"}) / 
	                   ($$ul{"speed"} * 1000);

	  my $minutes = int($total_time / 60);
	  my $seconds = int($total_time - $minutes * 60);

	  $time = "$minutes:$seconds";

	  $time = "$minutes:0$seconds" if ($seconds < 10);
	}

      $list->set_text($row, 3, $$ul{"speed"} . " Kbps");
      $list->set_text($row, 4, "$time");
    }
}

sub gtk_cancel_ul
{
  my $list = shift;

  foreach ($list->selection)
    { 
#      kill_ul($napster_sock, $_);

      my $num = $_ + 1;

      do_command($napster_sock, "/ul -kill $num");
    }
}

############################### Help Functions ################################

sub gtk_help
{
  my ($rows, $cols);
  my $win = Gtk::Window->new;
  my $box = Gtk::VBox->new(0, 0);
  my $table;
  my $item;
  my @items = sort keys %help_hash;

  $rows = int($#items / 3);
  $cols = 3;

  $table = Gtk::Table->new($rows, $cols, 0);

  my ($cur_row, $cur_col) = (0, 0);

  foreach $item (@items)
    {
      my $label = Gtk::Label->new($item);
      my $ev = Gtk::EventBox->new();
      my $align = Gtk::Alignment->new(0, 0.5, 0, 0);
      my $style = $label->style->copy;

      $align->add($ev);
      $ev->add($label);
      $ev->signal_connect("enter_notify_event", \&label_highlight, $label);
      $ev->signal_connect("leave_notify_event", \&label_unhighlight, $label);
      $ev->signal_connect("button_press_event", \&label_clicked, 
			  { Label => $label,
			    Table => $table,
			    Box => $box });

      $style->fg("normal", Gtk::Gdk::Color->parse_color("black"));
      $label->set_style($style);

      $table->attach($align,
		     $cur_col, $cur_col + 1, $cur_row, $cur_row + 1,
		     ["expand", "fill"], ["expand", "fill"], 8, 0);

      $cur_col++;

      if ($cur_col >= $cols)
        {
	  $cur_row++;
	  $cur_col = 0;
        }
    }
  
  $win->add($box);
  $box->pack_start($table, 0, 0, 0);

  $win->set_usize(600, 200);
  $win->signal_connect("delete_event", sub { $win->destroy() });

  $win->show_all();
}

sub label_highlight
{
  my ($w, $label) = @_;
  my $style = $label->style->copy;

  $style->fg("normal", Gtk::Gdk::Color->parse_color("blue"));

  $label->set_style($style);
}

sub label_unhighlight
{
  my ($w, $label) = @_;
  my $style = $label->style->copy;

  $style->fg("normal", Gtk::Gdk::Color->parse_color("black"));
  $label->set_style($style);
}

sub label_clicked
{
  my ($w, $data, $e) = @_;
  my $textbox;
  my $scroller;
  my $printer;
  my $button;

  return if ($e->{"button"} != 1);

  my $help_text = $help_hash{$data->{"Label"}->get()};

  $help_text = &$help_text() if ($help_text =~ /^CODE/);

  $textbox = Gtk::Text->new();
  $scroller = Gtk::ScrolledWindow->new(undef, undef);  
  $printer = GtkTextPrinter->new($textbox);

  $printer->{"colours"}->[0] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[1] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[2] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[3] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[4] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[5] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[6] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[7] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[8] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[9] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[10] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[11] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[12] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[13] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[14] = Gtk::Gdk::Color->parse_color("black");
  $printer->{"colours"}->[15] = Gtk::Gdk::Color->parse_color("black");

  $scroller->set_policy('automatic', 'automatic');
  $scroller->add($textbox);
  $printer->print($help_text);

  $data->{"Table"}->hide();
  $data->{"Box"}->pack_start($scroller, 1, 1, 0);

  $button = Gtk::Button->new("Back");
  $data->{"Box"}->pack_start($button, 0, 0, 0);
  $button->show();

  $button->signal_connect("clicked", \&back_pressed,
			  { Text => $scroller,
			    Table => $data->{"Table"} });


  $scroller->show_all();
}

sub back_pressed
{
  my ($w, $data) = @_;

  $data->{"Text"}->destroy();
  $data->{"Table"}->show();

  $w->destroy();
}

1;

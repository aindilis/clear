package Clear::Mod::GUI;

use BOSS::App::DBus;
use BOSS::App::GMMKeys;
use Clear::Mod::Reader::TabManager;
use PerlLib::Collection;
use PerlLib::SwissArmyKnife;

use Gtk3 -init;
use Time::HiRes qw(usleep);
use Tk qw(DoOneEvent DONT_WAIT);

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyClear MyMainWindow MyMenu MyGMMKeys MyNoteBook Readers ActiveReadList /

  ];

my $continueloop;
use constant
{
 PROGRAM_NAME => 'clear',
};

use constant
{
 PROGRAM_NAME => 'clear',
};

sub init {
  my ($self,%args) = @_;
  $self->MyClear($args{Clear});
  $self->MyMainWindow
    (MainWindow->new
     (
      -title => "Computer Learning Architecture",
      -height => 600,
      -width => 800,
     ));
  $self->MyMainWindow->focusmodel('passive');
  $self->MyMainWindow->resizable(1, 1);
  $UNIVERSAL::managerdialogtkwindow = $self->MyMainWindow;
  $menu = $self->MyMainWindow->Frame(-relief => 'raised', -borderwidth => '1');
  $menu->pack(-side => 'top'); # , -fill => 'x');
  $self->MyMenu($menu);
  #   $self->MyMenu
  #     ($self->MyMainWindow->menu
  #      ()
  #     );
  # my $menubutton = $menu->Menubutton(-text => "Tabs");
  # $menubutton->checkbutton(-label => "Tabs", -variable => \$open);
  $self->SetUpGlib();

  $menu_file_1 = $menu->Menubutton
    (
     -text => 'File',
     -tearoff => 0,
     -underline => 0,
    );
  $menu_file_1->command
    (
     -label => 'Load Readlist',
     -command => sub {
       $self->GetCurrentTab->SaveData();
     },
     -underline => 0,
    );
  $menu_file_1->command
    (
     -label => 'Load File',
     -command => sub {
       $self->GetCurrentTab->SaveData();
     },
     -underline => 0,
    );
  $menu_file_1->pack
    (
     -side => 'left',
    );


  ############################################################

  $menu_file_4 = $menu->Menubutton
    (
     -text => 'Select',
     -tearoff => 0,
     -underline => 0,
    );
  foreach my $action ("All","None","Invert","By Search","By Regex","By Entailment") {
    $menu_file_4->command
      (
       -label => $action,
       -command => sub {

       },
      );
  }
  $menu_file_4->pack
    (
     -side => 'left',
    );

  ############################################################

  $menu_file_2 = $menu->Menubutton
    (
     -text => 'View',
     -tearoff => 0,
     -underline => 0,
    );
  $menu_file_2->pack
    (
     -side => 'left',
    );

  ############################################################

  $menu_file_3 = $menu->Menubutton
    (
     -text => 'Action',
     -tearoff => 0,
     -underline => 0,
    );
  $menu_file_3->pack
    (
     -side => 'left',
    );

  $self->Readers
    (PerlLib::Collection->new
     (
      Type => 'Clear::Mod::Reader',
     ));
  $self->Readers->Contents({});

  $self->MyNoteBook
    ($self->MyMainWindow->Frame
     (-borderwidth => 3, -relief => 'groove')
     ->pack->
     NoteBook(-dynamicgeometry => 0));
  # $self->MainMenu($args{MainMenu});
  # $self->MyMenu($self->MainMenu->Menubutton(-text => "Tabs"));
}

sub SetUpGlib {
  my ($self,%args) = @_;
  $self->MyGMMKeys
    (BOSS::App::GMMKeys->new
     (
      AppName => 'org.frdcsa',
      Commands =>
      {
       Previous	        => \&CommandBackward,
       Next		=> \&CommandForward,
       Play		=> \&CommandPause,
       # Stop		=> \&CommandStop,
      },
     ));
  $self->MyGMMKeys->Start();
  Glib::Idle->add(sub { Gtk3::main_quit(); });
}

sub CommandPause {
  $UNIVERSAL::clear->CurrentDoc->CommandPause;
}

sub CommandBackward {
  $UNIVERSAL::clear->CurrentDoc->CommandBackward;
}

sub CommandForward {
  $UNIVERSAL::clear->CurrentDoc->CommandForward;
}

sub AddReader {
  my ($self,%args) = @_;
  my $id = $args{ReadList}->{ID};
  $self->ActiveReadList($id);

  my $tabname = $self->GetTabNameForID(ID => $id);
  my $tablabel = $tabname;
  my $myframe = $self->MyNoteBook->add
    (
     $id,
     -label => $tablabel,
     -raisecmd => sub
     {

     },
    );
  $myframe->Label(-text => $tabname)->pack;
  $self->Readers->Add
    (
     $id => Clear::Mod::Reader->new
	(
	 GUI => $self,
	 ReadList => $args{ReadList},
	 ReaderWindow => $myframe,
	 ReadListID => $id,
	));
  my $reader = $self->Readers->Contents->{$id};
  $reader->Execute();
  # $self->AddTabToTabMenu
  #   (
  #    Tabname => $tabname,
  #   );
  $self->MyNoteBook->pack(-expand => 1, -fill => "both");
  return $id;
}

sub GetTabNameForID {
  my ($self,%args) = @_;
  return "Tab for ".$args{ID};
}

sub GetTabLabelForID {
  my ($self,%args) = @_;
  my $tabname = $self->GetTabNameForID(ID => $args{ID});
  my $tablabel = $tabname;
  my $readlist = $self->Readers->Contents->{$args{ID}}->MyReadList;
  if (defined $readlist->CurrentDoc) {
    $tablabel = $readlist->CurrentDoc->OriginalFile;
  }
  return $tablabel;
}

sub UpdateTabName {
  my ($self,%args) = @_;
  return;
  my $tabname = $self->GetTabNameForID(ID => $args{ID});
  my $tablabel = $self->GetTabLabelForID(ID => $args{ID});
  print "<TabName: $tabname>\n";
  print "<TabLabel: $tablabel>\n";
  $self->MyNoteBook->pageconfigure
    (
     $tabname,
     -label => $tablabel,
    );
}

sub SetUpGlib {
  my ($self,%args) = @_;
  $self->MyGMMKeys
    (BOSS::App::GMMKeys->new
     (
      AppName => 'org.frdcsa',
      Commands =>
      {
       Previous	        => \&CommandBackward,
       Next		=> \&CommandForward,
       Play		=> \&CommandPause,
       # Stop		=> \&CommandStop,
      },
     ));
  $self->MyGMMKeys->Start();
  Glib::Idle->add(sub { Gtk3::main_quit(); });
}

sub CommandPause {
  print Dumper(Keys => [keys %{$UNIVERSAL::clear->CurrentDoc}]);
  $UNIVERSAL::clear->CurrentDoc->CommandPause;
}

sub CommandBackward {
  $UNIVERSAL::clear->CurrentDoc->CommandBackward;
}

sub CommandForward {
  $UNIVERSAL::clear->CurrentDoc->CommandForward;
}

sub Execute {
  my ($self,%args) = @_;
}

sub Listen {
  my ($self,%args) = @_;
  # print "Listen\n";
  my $count = 0;
  unless ($inMainLoop) {
    local $inMainLoop = 1;
    $continueloop = 1;
    while ($continueloop) {
      DoOneEvent(DONT_WAIT);
      Glib::Idle->add(sub { Gtk3::main_quit(); });
      Gtk3->main();
      usleep 1000;
      if (0) {
	$self->AgentListen
	  (
	   Timeout => int($args{TimeOut} / 10),
	  );
      }
      ++$count;
      if ($count > 10) {
	$continueloop = 0;
      }
    }
  }
}

sub MyMainLoop {
  my ($self,%args) = @_;
  print "MyMainLoop\n";
  $self->MyMainWindow->repeat
    (
     $args{TimeOut},
     sub {
       $continueloop = 0;
     },
    );
  unless ($inMainLoop) {
    local $inMainLoop = 1;
    $continueloop = 1;
    while ($continueloop) {
      # for my $i (1..30) {
      DoOneEvent();
      $self->MyGMMKeys->Stop();
      $self->MyGMMKeys->Start();
      # }
      if (0) {
	$self->AgentListen
	  (
	   Timeout => int($args{TimeOut} / 10),
	  );
      }
    }
  }
}

sub AgentListen {
  my ($self,%args) = @_;
  print "AgentListen\n";
  if ($UNIVERSAL::agent->RegisteredP) {
    $UNIVERSAL::agent->Listen
      (
       TimeOut => $args{TimeOut} || 0.05,
      );
  }
}

sub DESTROY {
  my ($self,%args) = @_;
  $self->MyGMMKeys->Stop();
}

1;

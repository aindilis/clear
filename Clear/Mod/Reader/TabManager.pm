package Clear::Mod::Reader::TabManager;

use Data::Dumper;

use Tk::NoteBook;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyReaderWindow MyNoteBook MainMenu MyMenu Tabs TabInfo ReadListID /

  ];

sub init {
  my ($self,%args) = @_;
  $self->ReadListID($args{ReadListID});
  $self->Tabs({});
  $self->TabInfo
    ({
      "Display" => {
		    Module => "Display",
		    Default => 1,
		   },
      "ReadList" => {
		     Module => "ReadList",
		     Default => 1,
		    },
      "Visualizer" => {
		       Module => "Visualizer",
		       Default => 1,
		      },
      "Preferences" => {
		       Module => "Preferences",
		       Default => 1,
		      },
     });
}

sub Execute {
  my ($self,%args) = @_;
  $self->StartReader(%args);
}

sub StartReader {
  my ($self,%args) = @_;
  $self->MyReaderWindow($args{ReaderWindow});
  # $self->MainMenu($args{MainMenu});
  $self->MyNoteBook($self->MyReaderWindow->NoteBook(-dynamicgeometry => 0));
  # $self->MyMenu($self->MainMenu->Menubutton(-text => "Tabs"));
  foreach my $tabname (qw(Display ReadList Visualizer Preferences)) {
    my $open = 0;
    if ($self->TabInfo->{$tabname}->{Default}) {
      $self->StartTab
	(
	 Tabname => $tabname,
	);
      $open = 1;
    }
    $self->AddTabToTabMenu
      (
       Tabname => $tabname,
       Open => $open,
      );
  }
  $self->MyNoteBook->pack(-expand => 1, -fill => "both");
  # $self->MyReaderWindow->pack();
}

sub StartTab {
  my ($self,%args) = @_;
  my $myframe = $self->MyNoteBook->add($args{Tabname}, -label => $args{Tabname});
  $myframe->#Label(-text => $args{Tabname})->
    pack(-fill => 'both', -expand => 1);
  my $modulename = "Clear::Mod::Reader::Tab::".$self->TabInfo->{$args{Tabname}}->{Module};
  # print Dumper({Modulename => $modulename});
  my $require = $modulename;
  $require =~ s/::/\//g;
  $require .= ".pm";
  my $fullrequire = "/var/lib/myfrdcsa/codebases/internal/clear/$require";
  if (! -f $fullrequire) {
    print "ERROR, no <<<$fullrequire>>>\n";
    return;
  }
  require $fullrequire;

  my $newtab = eval "$modulename->new(Frame => \$myframe, ReadListID => \$self->ReadListID)";
  my $errorstring = $@;
  if (defined $newtab) {
    $self->Tabs->{$args{Tabname}} = $newtab;
    $newtab->Execute();
  } else {
    print Dumper($args{Tabname});
    print $errorstring."\n";
  }
}

sub AddTabToTabMenu {
  my ($self,%args) = @_;
  my $open = $args{Open};
  # $self->MyMenu->checkbutton(-label => $args{Tabname}, -variable => \$open);
}

1;

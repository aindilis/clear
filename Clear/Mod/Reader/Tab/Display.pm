package Clear::Mod::Reader::Tab::Display;

# go ahead and display the current page

# show item being read, along with text of it being read

use base qw(Clear::Mod::Reader::Tab);

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyFrame MyText Doc Buttons /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyFrame($args{Frame});
  $self->Buttons({});
}

sub Execute {
  my ($self,%args) = @_;
  my $buttonframe1 = $self->MyFrame->Frame();
  my $buttonframe2 = $self->MyFrame->Frame();
  my $buttons = {
		 "Activate" => {Sub => sub {$self->Doc->CommandActivate}},
		 "|<<" => {Sub => sub {$self->Doc->CommandGoto(Relative => "beginning");}},
		 "<<" => {Sub => sub {$self->Doc->CommandGoto(Relative => "previous 10");}},
		 "<" => {Sub => sub {$self->Doc->CommandGoto(Relative => "previous line");}},
		 ">" => {Sub => sub {$self->Doc->CommandGoto(Relative => "next line");}},
		 ">>" => {Sub => sub {$self->Doc->CommandGoto(Relative => "next 10");}},
		 ">>|" => {Sub => sub {$self->Doc->CommandGoto(Relative => "ending");}},
		 "Quit" => {Sub => sub {$self->Doc->CommandQuit}},
		 "Save" => {Sub => sub {$self->Doc->SaveMetaData}},
		 "Restart TTS" => {Sub => sub {$self->Doc->CommandRestartTTS}},
		 "Pause" => {Sub => sub {$self->Doc->CommandPause}},
		 "Jump to Item in ReadList" => {Sub => sub {$self->Doc->CommandJumpTo}},
		 "Ignore Current Item" => {Sub => sub {$self->Doc->CommandIgnore}},
		 "Volume" => {Sub => sub {$self->Doc->CommandVolume}},
		 "Duration (Voice Speed)" => {Sub => sub {$self->Doc->CommandDuration}},
		 "Goto Sentence" => {Sub => sub {$self->Doc->CommandGoto}},
		};

  foreach my $key (reverse ("Activate","|<<","<<","<","Pause",">",">>",">>|","Restart TTS","Jump to Item in ReadList","Ignore Current Item")) {
    $self->Buttons->{$key} = $buttonframe1->Button
      (
       -text => $key,
       -command => sub {
	 print $key."\n";
	 $buttons->{$key}->{Sub}->();
       },
      )->pack(-side => 'right');
  }
  $buttonframe1->pack;

  foreach my $key (reverse ("Duration","Volume","Goto Sentence","Save","Quit")) {
    $self->Buttons->{$key} = $buttonframe2->Button
      (
       -text => $key,
       -command => sub {
	 print $key."\n";
	 $buttons->{$key}->{Sub}->();
       },
      )->pack(-side => 'right');
  }

  my $searchtext = "";
  my $search = $buttonframe2->Entry
    (
     -relief       => 'sunken',
     -borderwidth  => 2,
     -textvariable => \$searchtext,
     -width        => 30,
    )->pack(-side => 'left');
  $buttonframe2->Button
    (
     -text => "Search",
     -command => sub {
       $self->Doc->CommandSearch(Search => $searchtext);
     },
    )->pack(-side => 'right');
  $buttonframe2->pack;

  my $textframe = $self->MyFrame->Frame();
  my $text = $textframe->Text
    (
     -width => 120,
     -height => 30,
    );
  $self->MyText($text);
  my $scrollbar = $textframe->Scrollbar
    ();
  $scrollbar->pack(-side => "right", -fill => "y");
  $self->MyText->pack(-side => "left", -fill => "both", -expand => 1);
  $scrollbar->configure
    (
     -command => ['yview', $text],
    );
  $self->MyText->configure
    (
     -yscrollcommand => ['set', $scrollbar],
    );
  $textframe->pack(-fill => "both", -expand => 1);

  $self->MyFrame->pack();
}

1;

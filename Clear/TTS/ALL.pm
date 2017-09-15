package Clear::TTS::ALL;

use ALL::TTS;
use Manager::Dialog qw(Message);
use MyFRDCSA qw(ConcatDir);
use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw / MyALLTTS /
  ];

sub init {
  my ($self,%args) = @_;
  $self->MyALLTTS
    (ALL::TTS->new());
}

sub StartTTS {
  my ($self,%args) = @_;
  Message
    (Message => "Initializing TTS engine...");
}

sub Say {
  my ($self,%args) = @_;
  $self->MyALLTTS->Speak
    (
     Text => $args{Text},
    );
  # print $text."\n";
}

sub RestartTTS {
  my ($self,%args) = @_;
  $self->StartTTS;
}

sub ChangeTTSSpeed {
  my ($self,%args) = @_;
  # $self->RestartTTS;
}

sub ChangeVolume {
  my ($self,%args) = @_;
  # print out to the config file, then reload the tts
  system "aumix -v $args{Volume}";
}

sub CheckForInput {
  my ($self,%args) = @_;
  return $self->MyALLTTS->CheckForInput();
}

sub ExecuteCommandTriggers {
  my ($self,%args) = @_;
  my $char = $args{Command};
  if ($char =~ /[dgijkpsv]/) {
    # $self->RestartTTS;
  } else {
    # $self->TTSServer->waitfor
  }
}


1;

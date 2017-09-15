package Clear::TTS::Festival;

use PerlLib::SwissArmyKnife;
use Manager::Dialog qw(Message);
use MyFRDCSA qw(ConcatDir);


use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw / TTSServer FestivalConfigFile /
  ];

sub init {
  my ($self,%args) = @_;
  $self->FestivalConfigFile
    (ChooseFirst
     (
      Items => [
		"/etc/clear/fest.conf",
		ConcatDir($args{SystemDir},"fest.conf"),
	       ],
     ));
}

sub StartTTS {
  my ($self,%args) = @_;
  Message(Message => "Initializing TTS engine...");
  system "killall -9 festival";
  sleep 3;
  system "festival --server ".$self->FestivalConfigFile." &";
  sleep 7;
  $self->TTSServer(Net::Telnet->new(Timeout=>3600,
				    Errmode=>'die'));
  $self->TTSTelnetOpen;
}

sub Say {
  my ($self,%args) = @_;
  my $text = $args{Text};
  my $command = "(SayText \"$text\")";
  # print $command."\n";
  $self->TTSServer->print($command);
}

sub RestartTTSConnect {
  my ($self,%args) = @_;
  $self->TTSTelnetClose;
  $self->TTSTelnetOpen;
}

sub TTSTelnetOpen {
  my ($self,%args) = @_;
  $self->TTSServer->open(Host => "localhost",
			 Port => "1314");
}

sub TTSTelnetClose {
  my ($self,%args) = @_;
  $self->TTSServer->close();
}

sub RestartTTS {
  my ($self,%args) = @_;
  system "killall -9 festival";
  $self->StartTTS;
}

sub ChangeTTSSpeed {
  my ($self,%args) = @_;
  # print out to the config file, then reload the tts
  my $duration = $args{Duration} || 1.0;
  my $OUT;
  my $templatefile = "/etc/clear/fest.conf.template";
  my $c = `cat $templatefile`;
  $c =~ s/<DURATION>/$duration/;
  open (OUT,">/etc/clear/fest.conf") or die "ouch\n";
  print OUT $c;
  close (OUT);
  $self->RestartTTS;
}

sub ChangeVolume {
  my ($self,%args) = @_;
  # print out to the config file, then reload the tts
  system "aumix -v $args{Volume}";
}

sub CheckForInput {
  my ($self,%args) = @_;
  $self->TTSServer->waitfor
    (
     Match => '/ft_StUfF_keyOK/',
     Timeout => 0, # $self->DefaultTimeOut,
     Errmode => "return",
    );
  my $mess = $self->TTSServer->errmsg;
  if ($mess =~ /pattern match timed-out/) {
    return "timeout";
  }
}

sub ExecuteCommandTriggers {
  my ($self,%args) = @_;
  my $char = $args{Command};
  if ($char =~ /[dgijkpsv]/) {
    $self->RestartTTS;
    # $self->RestartTTSConnect;
  } else {
    $self->TTSServer->waitfor
      (
       Match => '/ft_StUfF_keyOK/',
       Errmode => "return",
      );
  }
}


1;

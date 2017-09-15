package Clear::Quiz;

use Manager::Dialog qw (Message);

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw( Title TimeLimit Number Score Questions ) ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Title($args{Title} || "");
  $self->TimeLimit($args{TimeLimit} || "");
  $self->("\"".$self->OriginalFile."\"");
  $self->ParsedFile($args{ParsedFile});
  $self->QuotedParsedFile("\"".$self->ParsedFile."\"");
}

sub StartQuiz {
  message "Quiz: ".$self->Title;
  if ($self->TimeLimit) {
    message "Time Limit: ".$self->TimeLimit;
  }
  foreach my $question ($self->Questions) {
    $self->AskQuestion(%{$question});
  }
}

sub AskQuestion {
  my ($self,%args) = (shift,@_);
  if ($args{Type} eq "multiple choice") {

#  } elsif ($args{Type} eq "essay") {
  } else {
      print "\nQuestion ".$self->Number."\n";
      print wrap("", "", ($args{Question}))."\n> ";
      $response = <STDIN>;
      chomp $response;
      if (similarity($response,$word) > ($args{Similarity} || 0.75)) {
	print "Correct! ($word)\n";
	$self->Score($self->Score + ($args{Score} || 1));
      } else {
	print "Incorrect! ($word)\n";
      }
  }
}

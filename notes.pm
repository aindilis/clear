	if (exists $self->Config->CLIConfig->{'--test-loading'}) {
	  if (! $seen) {
	    ++$seen;
	    $self->Queue(["/home/andrewdo/temp.pdf"]);
	  } elsif ($seen == 1) {
	    ++$seen;
	    print Dumper($self->MyReadList);
	    if ($self->MyGUI) {
	      $self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->
		MyTabManager->Tabs->{ReadList}->Redisplay();
	    }
	    $self->MyReadList->Process;
	    $self->Queue([]);
	  }
	} else {
	  if ($self->MyGUI) {
	    $self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->
	      MyTabManager->Tabs->{ReadList}->Redisplay();
	  }
	  $self->MyReadList->Process;

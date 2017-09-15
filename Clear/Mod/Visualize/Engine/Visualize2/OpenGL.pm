package Clear::Mod::Visualize::Engine::Visualize2::OpenGL;

# ("created-by" "PPI-Convert-Script-To-Module")

use Clear::Mod::Visualize::Engine::Visualize2::VideoExport;
use Manager::Dialog qw(ApproveCommands);
use MyFRDCSA qw(ConcatDir);
use PerlLib::SwissArmyKnife;
use System::WWW::GoogleImages2;

use OpenGL qw/ :all /;
use OpenGL::Image;
use Time::HiRes qw(gettimeofday tv_interval);
use constant ESCAPE => 27;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Counter GoogleImages Images ImagesSequence Search XCord YCord
   ZCord MyVideoExport Width Height FrameRate Paused FrameNumber Debug
   Directory CleanedSearch /

  ];

sub init {
  my ($self,%args) = @_;
  $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/internal/clear";
  $self->GoogleImages
    (System::WWW::GoogleImages2->new());
  $self->XCord(1);
  $self->YCord(1);
  $self->ZCord(0);
  $self->Counter(0);
  $self->Images({});
  $self->ImagesSequence([]);
  $self->Paused(0);
  $self->FrameNumber(0);
}

sub Execute {
  my ($self,%args) = @_;
  if (exists $args{Search}) {
    $self->Search($args{Search});
    my $cleanedsearch = $self->Search;
    $cleanedsearch =~ s/[^\w]+/_/g;
    $self->CleanedSearch($cleanedsearch);
  }
  if ($args{ExportVideo}) {
    $self->MyVideoExport
      (
       Clear::Mod::Visualize::Engine::Visualize2::VideoExport->new
      );
    $self->MyVideoExport->SelectVideoOptions;
    $self->Width($self->MyVideoExport->Resolution->[0]);
    $self->Height($self->MyVideoExport->Resolution->[1]);
    $self->FrameRate($self->MyVideoExport->FrameRate);
    $self->Directory(ConcatDir($UNIVERSAL::systemdir,"data","videos",$self->CleanedSearch));
    system "mkdir -p ".shell_quote($self->Directory);
  }
  if (! $self->Width) {
    $self->Width($args{Width} || 640);
    $self->Height($args{Height} || 480);
  }

  glutInit;
  glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA);
  glutInitWindowSize($self->Width, $self->Height);
  glutInitWindowPosition(0, 0);
  $window = glutCreateWindow("CLEAR Visualization");
  glutDisplayFunc(sub {$self->DrawGLScene;});
  glutIdleFunc(sub {$self->DrawGLScene;});
  glutReshapeFunc
    (sub {
       my ($width,$height) = @_;
       $self->ReSizeGLScene
	 (
	  Width => $width,
	  Height => $height,
	 );
     });
  glutKeyboardFunc
    (sub {
       my ($key,$x,$y) = @_;
       $self->keyPressed
	 (
	  Key => $key,
	  X => $x,
	  Y => $y,
	 );
     });
  $self->InitGL;
  if ($UNIVERSAL::conf->{'-f'} or $args{FullScreen}) {
    glutFullScreen;
  }
  if (exists $args{Search}) {
    $self->SearchFor
      (
       Search => $args{Search},
      );
  }
  glutMainLoop;
  return 1;
}

sub SearchFor {
  my ($self,%args) = @_;
  return unless defined $self->Search;
  my @res = $self->GoogleImages->Search
    (
     Search => $self->Search,
    );
  $self->ImagesSequence
    (\@res);
  print Dumper($self->ImagesSequence);
  $self->LoadNextImage();
}

sub View {
  my ($self,%args) = @_;
  # unshift it onto the image sequence, then load text image
  unshift @{$self->ImagesSequence}, $args{Item};
  $self->LoadNextImage();
}

sub LoadNextImage {
  my ($self,%args) = @_;
  my $entry;
  my $image;
  do {
    $entry = shift @{$self->ImagesSequence};
    return if ! defined $entry;
    $image = {};
    $image->{ImageFile} = $entry->Loc;
    $image->{Tex1} = new OpenGL::Image
      (
       source => $image->{ImageFile},
      );
    $image->{TexID} = glGenTextures_p(5);
    if (defined $image->{Tex1}) {
      ($image->{IFMT},$image->{FMT},$image->{Type}) = $image->{Tex1}->Get('gl_internalformat','gl_format','gl_type');
      ($image->{W},$image->{H}) = $image->{Tex1}->Get('width','height');
    }
  } while (! defined $image->{Tex1} or $image->{W} > 1000 or $image->{H} > 1000);
  return if ! defined $image;
  if ($image->{W} != 0) {
    $image->{AspectRatio} = $image->{H} / $image->{W};
  } else {
    $image->{AspectRatio} = 1;
  }
  $image->{VertexX} = 1/$image->{AspectRatio};
  $image->{VertexY} = 1;
  $image->{ZPosition} = 0;
  $image->{Alpha} = 0;
  $image->{Diff} = 0.003;
  $image->{StartingTime} = gettimeofday();
  $image->{PausedDuration} = 0;
  $image->{LastTime} = $image->{StartingTime};
  $self->Counter($self->Counter + 1);
  $image->{ID} = $self->Counter;
  $self->Images->{$self->Counter} = $image;
}

sub InitGL {
  my ($self,%args) = @_;
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClearDepth(1.0);
  glDepthFunc(GL_LESS);
  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);
}

sub ReSizeGLScene {
  my ($self,%args) = @_;
  # Shift width and height off of @_, in that order
  my ($width, $height) = ($args{Width},$args{Height});

  # Prevent divide by zero error if window is too small
  if ($height == 0) {
    $height = 1;
  }

  # Reset the current viewport and perspective transformation
  glViewport(0, 0, $width, $height);

  # Re-initialize the window (same lines from InitGL)
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  # Calculate the aspect ratio of the Window
  gluPerspective(45.0, $width/$height, 0.1, 100.0);
  glMatrixMode(GL_MODELVIEW);
}

sub DrawGLScene {
  my ($self,%args) = @_;
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0.0, 0.0, -4.5);
  glPushMatrix();
  glEnable(GL_TEXTURE_2D);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  foreach my $hashkey (keys %{$self->Images}) {
    my $image = $self->Images->{$hashkey};
    # print "<$hashkey><".$image->{ZPosition}.">\n";
    my $currenttime = gettimeofday();
    my $deltatime;
    if (defined $self->FrameRate) {
      $deltatime = 1 / $self->FrameRate;
    } else {
      $deltatime = $currenttime - $image->{LastTime};
    }
    if ($self->Paused) {
      $image->{PausedDuration} += $deltatime;
    } else {
      my $elapsedtime;
      if (defined $self->FrameRate) {
	$elapsedtime = $self->FrameNumber * 1 / $self->FrameRate;
      } else {
	$elapsedtime = (($currenttime - $image->{StartingTime}) - $image->{PausedDuration});
      }
      $image->{ZPosition} = $elapsedtime * 0.175;
      $image->{Alpha} += $image->{Diff} * $elapsedtime;
      if ($image->{Alpha} >= 1.5) {
	$image->{Diff} *= -1;
      }
      if ($image->{Diff} < 0 and $image->{Alpha} < 1 and ! exists $image->{NextLoaded}) {
	$image->{NextLoaded} = 1;
	$self->LoadNextImage();
      }
      if ($image->{Alpha} < 0) {
	delete $self->Images->{$image->{ID}};
      }
    }
    $image->{LastTime} = $currenttime;
    glBindTexture(GL_TEXTURE_2D, $image->{TexID});
    glTexImage2D_c(GL_TEXTURE_2D, 0, $image->{IFMT}, $image->{W}, $image->{H}, 0, $image->{FMT}, $image->{Type}, $image->{Tex1}->Ptr());
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glBegin (GL_QUADS);
    glColor4f(1.0,1.0,1.0,$image->{Alpha}); #white to display the texture
    glTexCoord2d(0.0, 0.0); glVertex3f(-$image->{VertexX},-$image->{VertexY},1.0 + $image->{ZPosition});
    glTexCoord2d(1.0, 0.0); glVertex3f($image->{VertexX},-$image->{VertexY},1.0 + $image->{ZPosition});
    glTexCoord2d(1.0, 1.0); glVertex3f($image->{VertexX},$image->{VertexY},1.0 + $image->{ZPosition});
    glTexCoord2d(0.0, 1.0); glVertex3f(-$image->{VertexX},$image->{VertexY},1.0 + $image->{ZPosition});
    glEnd();
  }
  glPopMatrix();
  glFlush();
  glutSwapBuffers;
  if (defined $self->MyVideoExport) {
    $self->SaveScreenShot
      (
       Additional => "-".sprintf("%06i",$self->FrameNumber),
      );
    $self->FrameNumber($self->FrameNumber + 1);
  }
}

sub keyPressed {
  my ($self,%args) = @_;
  # Shift the unsigned char key, and the x,y placement off @_, in
  # that order.
  my ($key, $x, $y) = ($args{Key},$args{X},$args{Y});
  # If escape is pressed, kill everything.
  if ($key == ESCAPE or $key == ord('q')) {
    # Shut down our window
    glutDestroyWindow($window);
    if (defined $self->MyVideoExport) {
      $self->GenerateMovieFromImageFiles();
    }
    # Exit the program...normal termination.
    exit(0);
  } elsif ($key == ord('n')) {
    $self->Images
      ({});
    $self->LoadNextImage;
  } elsif ($key == ord('a')) {
    $self->LoadNextImage;
  } elsif ($key == ord('s')) {
    $self->SaveScreenShot;
  } elsif ($key == ord('p')) {
    $self->TogglePause();
  } elsif ($key == ord('r')) {
    $self->Resize();
  }
}

sub TogglePause {
  my ($self,%args) = @_;
  $self->Paused(! $self->Paused);
}

sub MyImages {
  my ($self,%args) = @_;
  my $items =
    [
     "add subtitles, image labels",
     "we want it to use large/hi-res images effectively, panning through them, etc,",
     "want to eliminate redundant images using that image similarity software",
    ];
  # "completed: add the ability to download simulatenously and in the background",
}

sub PossibleUseCases {
  my ($self,%args) = @_;
  my $items =
    [
     "evangelist",
     "clear",
     "texts",
     "coauthor",
     "quac (read and display the answer to a question)",
     "media-library, entertainment-center (for visualizing songs)",
     "documentary-generator",
     "genealogy, family-history",
     "irish library",
     "film making (as an aid to arbitrary film making)",
    ];
}

sub Transitions {
  my ($self,%args) = @_;
  my $items =
    [
     "for now, cuts, and fades, add fade to white, fade from white,",
     "black, etc",
    ];
}

sub CameraControl {
  my ($self,%args) = @_;
  my $items =
    [
     "add zooming out",
     "add translation",
     "zooming in or away from a point such as a face",
     "add still",
     "zoom and stop",
     "we want it to use large/hi-res images effectively, panning through them, etc,",
    ];
}

sub SaveScreenShot {
  my ($self,%args) = @_;
  print "1\n" if $self->Debug;
  my $additional = $args{Additional};
  my $directory = $self->Directory;
  foreach my $key (keys %{$self->Images}) {
    print "2\n" if $self->Debug;
    my($def_fmt,$def_type) = $self->Images->{$key}->{Tex1}->Get('gl_format','gl_type');
    print "3\n" if $self->Debug;
    my $image = new OpenGL::Image
      (
       engine => 'Magick',
       width => $self->Width,
       height => $self->Height,
      );
    print "4\n" if $self->Debug;
    # print Dumper([0, 0, $self->Width, $self->Height, $def_fmt, $def_type, $image->Ptr()]);
    # print "4.a\n";
    # OpenGL::Array
    # my @p = glReadPixels_p(0, 0, $self->Width, $self->Height, $def_fmt, $def_type);
    # print Dumper(\@p);
    # glReadPixels(0, 0, $self->Width, $self->Height, $def_fmt, $def_type, $image->Ptr());
    glReadPixels_c(0, 0, $self->Width, $self->Height, $def_fmt, $def_type, $image->Ptr());
    $image->Sync();
    $image->Native->Blur();
    $image->SyncOGA();
    glDrawPixels_c($self->Width, $self->Height, $def_fmt, $def_type, $image->Ptr());
    print "5\n" if $self->Debug;
    $image->Save("$directory/screenshot-$key$additional.tga");
    print "6\n" if $self->Debug;
  }
  print "7\n" if $self->Debug;
}

sub Resize {
  my ($self,%args) = @_;

}

sub GenerateMovieFromImageFiles {
  my ($self,%args) = @_;
  my $outputdir = $self->Directory;
  my $outputmoviefile = "movie.mp4";
  my $bitrate = 144000;
  my $command = "ffmpeg -r ".$self->FrameRate." -b $bitrate -i $outputdir/screenshot-1-%06d.tga $outputdir/$outputmoviefile";
  my $command2 = "mencoder \"mf://*.tga\" -mf fps=25 -o test.avi -ovc lavc -lavcopts vcodec=msmpeg4v2:vbitrate=800";
  # ffmpeg -r 25 -b 144000 -i screenshot-1-%06d.tga test1800.mp4
  ApproveCommands
    (
     Commands => [$command],
     Method => "parallel",
    );
}

1;

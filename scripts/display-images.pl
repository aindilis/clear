#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;
use System::WWW::GoogleImages;

use OpenGL qw/ :all /;
use OpenGL::Image;

use Time::HiRes qw(gettimeofday tv_interval);

$UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/documentary-generator";

my $search = $ARGV[0];
my $googleimages = System::WWW::GoogleImages->new;

my @imagessequence = $googleimages->Search
  (
   Search => $search,
  );

print Dumper(\@imagessequence);

use constant ESCAPE => 27;
# Global variable for our window
my $window;
my $xCord = 1;
my $yCord = 1;
my $zCord = 0;

my $images = {
	     };
my $counter = 0;

sub LoadNextImage {
  my %args = @_;
  my $entry;
  my $image;
  do {
    $entry = shift @imagessequence;
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
  $image->{LastTime} = $image->{StartingTime};
  $image->{ID} = ++$counter;
  $images->{$counter} = $image;
}

LoadNextImage();

# A general GL initialization function
# Called right after our OpenGL window is created
# Sets all of the initial parameters
sub InitGL {

  # Shift the width and height off of @_, in that order
  my ($width, $height) = @_;

  # Set the background "clearing color" to black
  glClearColor(0.0, 0.0, 0.0, 0.0);

  # Enables clearing of the Depth buffer
  glClearDepth(1.0);

  # The type of depth test to do
  glDepthFunc(GL_LESS);

  # Enables depth testing with that type
  glEnable(GL_DEPTH_TEST);

  # Enables smooth color shading
  glShadeModel(GL_SMOOTH);

  # Reset the projection matrix
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  # Reset the modelview matrix
  glMatrixMode(GL_MODELVIEW);
}

# The function called when our window is resized
# This shouldn't happen, because we're fullscreen
sub ReSizeGLScene {

  # Shift width and height off of @_, in that order
  my ($width, $height) = @_;

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


# The main drawing function.
sub DrawGLScene {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0.0, 0.0, -4.5);
  glPushMatrix();
  glEnable(GL_TEXTURE_2D);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  foreach my $hashkey (keys %$images) {
    my $image = $images->{$hashkey};
    # print "<$hashkey><".$image->{ZPosition}.">\n";
    my $currenttime = gettimeofday();
    my $elapsedtime = ($currenttime - $image->{StartingTime});
    my $deltatime = $currenttime - $image->{LastTime};
    $image->{LastTime} = $currenttime;
    $image->{ZPosition} = $elapsedtime * 0.175;
    $image->{Alpha} += $image->{Diff} * $elapsedtime;
    if ($image->{Alpha} >= 1.5) {
      $image->{Diff} *= -1;
    }
    if ($image->{Diff} < 0 and $image->{Alpha} < 1 and ! exists $image->{NextLoaded}) {
      $image->{NextLoaded} = 1;
      LoadNextImage();
    }
    if ($image->{Alpha} < 0) {
      delete $images->{$image->{ID}};
    }

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
}

# The function called whenever a key is pressed.
sub keyPressed {
  # Shift the unsigned char key, and the x,y placement off @_, in
  # that order.
  my ($key, $x, $y) = @_;
  # If escape is pressed, kill everything.
  if ($key == ESCAPE or $key == ord('q')) {
    # Shut down our window
    glutDestroyWindow($window);

    # Exit the program...normal termination.
    exit(0);
  } elsif ($key == ord('n')) {
    $images = {};
    LoadNextImage();
  } elsif ($key == ord('a')) {
    LoadNextImage
      ();
  }
}

# --- Main program ---

# Initialize GLUT state
glutInit;

# Depth buffer */
glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA);

# Get a 640 x 480 window
glutInitWindowSize(640, 480);

# The window starts at the upper left corner of the screen
glutInitWindowPosition(0, 0);

# Open the window
$window = glutCreateWindow("CLEAR Visualization");

# Register the function to do all our OpenGL drawing.
glutDisplayFunc(\&DrawGLScene);

# Go fullscreen.  This is as soon as possible.
#glutFullScreen;

# Even if there are no events, redraw our gl scene.
glutIdleFunc(\&DrawGLScene);

# Register the function called when our window is resized.
glutReshapeFunc(\&ReSizeGLScene);

# Register the function called when the keyboard is pressed.
glutKeyboardFunc(\&keyPressed);

# Initialize our window.
InitGL(640, 480);

# Start Event Processing Engine
glutFullScreen;
glutMainLoop;

return 1;


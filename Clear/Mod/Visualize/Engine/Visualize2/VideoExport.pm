package Clear::Mod::Visualize::Engine::Visualize2::VideoExport;

use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Resolution FrameRate VideoModes FrameRates /

  ];

sub init {
  my ($self,%args) = @_;
  $self->VideoModes
    ([
      {
       Desc => "Video CD",
       Resolution => [352,240],
       Format => "(NTSC)",
       AspectRatio => "4:3 (non-square pixels)",
       Pixels => "84,480",
      },
      {
       Desc => "Video CD",
       Resolution => [352,288],
       Format => "(PAL)",
       AspectRatio => "4:3 (non-square pixels)",
       Pixels => "101,376",
      },
      {
       Desc => "UMD",
       Resolution => [480,272],
       Format => "",
       AspectRatio => "~16:9",
       Pixels => "130,560",
      },
      {
       Desc => "China Video Disc",
       Resolution => [352,480],
       Format => "(NTSC)",
       AspectRatio => "4:3 (non-square pixels)",
       Pixels => "168,960",
      },
      {
       Desc => "China Video Disc",
       Resolution => [352,576],
       Format => "(PAL)",
       AspectRatio => "4:3 (non-square pixels)",
       Pixels => "202,725",
      },
      {
       Desc => "SVCD",
       Resolution => [480,480],
       Format => "(NTSC)",
       AspectRatio => "4:3 (non-square pixels)",
       Pixels => "230,400",
      },
      {
       Desc => "SVCD",
       Resolution => [480,576],
       Format => "(PAL)",
       AspectRatio => "4:3 (non-square pixels)",
       Pixels => "276,480",
      },
      {
       Desc => "SDTV 480i, EDTV 480p",
       Resolution => [640,480],
       Format => "",
       AspectRatio => "4:3 or 16:9",
       Pixels => "307,200",
      },
      {
       Desc => "SDTV",
       Resolution => [704,480],
       Format => "",
       AspectRatio => "4:3 or 16:9",
       Pixels => "337,920",
      },
      {
       Desc => "SDTV",
       Resolution => [852,480],
       Format => "",
       AspectRatio => "4:3 or 16:9",
       Pixels => "408,960",
      },
      {
       Desc => "DVD",
       Resolution => [720,480],
       Format => "(NTSC)",
       AspectRatio => "4:3 or 16:9 (non-square pixels)",
       Pixels => "345,600",
      },
      {
       Desc => "DVD",
       Resolution => [720,576],
       Format => "(PAL)",
       AspectRatio => "4:3 or 16:9 (non-square pixels)",
       Pixels => "414,720",
      },
      {
       Desc => "720p (HDTV, Blu-ray)",
       Resolution => [1280,720],
       Format => "",
       AspectRatio => "16:9",
       Pixels => "921,600",
      },
      {
       Desc => "1080p, 1080i (HDTV, Blu-ray)",
       Resolution => [1920,1080],
       Format => "",
       AspectRatio => "16:9",
       Pixels => "2,073,600",
      },
     ]);
  $self->FrameRates
    ([
      {
       Name => "50i",
       Rate => "25",
       Desc => "50i (50 interlaced fields = 25 frames) is the standard video field rate per second for PAL and SECAM television.",
      },
      {
       Name => "60i",
       Rate => "29.97",
       Desc => "60i (actually 59.94, or 60 x 1000/1001  to be more precise; 60 interlaced fields = 29.97 frames) is the standard video field rate per second for NTSC television (e.g. in the US), whether from a broadcast signal, DVD, or home camcorder. This interlaced field rate was developed separately by Farnsworth and Zworykin in 1934,[1] and was part of the NTSC television standards effective in 1941. When NTSC color was introduced in 1953, the older rate of 60 fields per second was reduced by a factor of 1000/1001 to avoid interference between the chroma subcarrier and the broadcast sound carrier.",
      },
      {
       Name => "30p",
       Rate => "30",
       Desc => "30p or 30-frame progressive, is a noninterlaced format and produces video at 30 frames per second. Progressive (noninterlaced) scanning mimics a film camera's frame-by-frame image capture and gives clarity for high speed subjects and a cinematic-like appearance. Shooting in 30p mode offers video with no interlace artifacts. The widescreen film process Todd-AO used this frame rate in 1954–1956.[2]",
      },
      {
       Name => "24p",
       Rate => "24",
       Desc => "The 24p frame rate is also a noninterlaced format, and is now widely adopted by those planning on transferring a video signal to film. Film and video makers turn to 24p for the \"cine\"-look even if their productions are not going to be transferred to film, simply because of the \"look\" of the frame rate. When transferred to NTSC television, the rate is effectively slowed to 23.976 frame/s, and when transferred to PAL or SECAM it is sped up to 25 frame/s. 35 mm movie cameras use a standard exposure rate of 24 frames per second, though many cameras offer rates of 23.976 frame/s for NTSC television and 25 frame/s for PAL/SECAM. The 24 frame/s rate became the de facto standard for sound motion pictures in the mid-1920s.[3]",
      },
      {
       Name => "25p",
       Rate => "25",
       Desc => "25p is a video format which runs twenty-five progressive frames per second. This framerate is derived from the PAL television standard of 50i (or 50 interlaced fields per second). While 25p captures only half the motion that normal 50i PAL registers, it yields a higher vertical resolution on moving subjects. It is also better suited to progressive-scan output (e.g., on LCD displays, computer monitors and projectors) because the interlacing is absent. Like 24p, 25p is often used to achieve \"cine\"-look."
      },
      {
       Name => "50p",
       Rate => "50",
       Desc => "50p and 60p is a progressive format used in high-end HDTV systems. While it is not technically part of the ATSC or DVB broadcast standards, it is rapidly gaining ground in the areas of set-top boxes and video recordings.[citation needed]",
      },
      {
       Name => "60p",
       Rate => "60",
       Desc => "50p and 60p is a progressive format used in high-end HDTV systems. While it is not technically part of the ATSC or DVB broadcast standards, it is rapidly gaining ground in the areas of set-top boxes and video recordings.[citation needed]",
      },
      {
       Name => "72p",
       Rate => "72",
       Desc => "is currently an experimental progressive scan format. Major institutions such as Snell & Wilcox have demonstrated 720p72 pictures as a result of earlier analogue experiments, where 768 line television at 75 Hz looked subjectively better than 1150 line 50 Hz progressive pictures with higher shutter speeds available (and a corresponding lower data rate).[4] Modern TV cameras such as the Red, can use this frame rate for creative effects such as slow motion (replaying at 24 fps). 72fps was also the frame rate at which emotional impact peaked[5] to the viewer as measured by Douglas Trumbull that led to the Showscan film format."
      },
     ]);
}

sub SelectVideoOptions {
  my ($self,%args) = @_;
  if ($args{Resolution}) {
    $self->Resolution($args{Resolution});
  } else {
    my $entry = ChooseByProcessor
      (
       Values => $self->VideoModes,
       Processor => sub {
	 return $_->{Resolution}->[0]."x".$_->{Resolution}->[1]."\t".$_->{Desc};
       },
      );
    $self->Resolution($entry->[0]->{Resolution});
  }
  if ($args{FrameRate}) {
    $self->FrameRate($args{FrameRate});
  } else {
    my $entry = ChooseByProcessor
      (
       Values => $self->FrameRates,
       Processor => sub {
	 return $_->{Name}."\t".$_->{Rate};
       },
      );
    $self->FrameRate($entry->[0]->{Rate});
  }
}

sub CaptureFrame {
  my ($self,%args) = @_;
  my $items =
    [
     "get the individual frames with glReadPixels(), and convert them to the appropriate video",
     "have the time step controllable, and have everything a parameterization of the time",
    ];
}

sub BuildVideoFromFrames {
  my ($self,%args) = @_;
  # need to know things like what video 
}

1;

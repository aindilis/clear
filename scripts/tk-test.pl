#!/usr/bin/perl
use warnings;
use strict;
use Image::Magick;
use Tk;
#use Tk::JPEG;
#use Tk::PNG;
use MIME::Base64;

my $image = Image::Magick->new;
$image->Read("/usr/share/kde4/apps/marble/data/maps/earth/srtm/4/000013/000013_000015.jpg");

# #fake a PGM then convert it to gif
# my $image = Image::Magick->new(
#    size => "600x600",
#               );
# $image->Read("xc:white");
# $image->Draw(
#    primitive => 'line',
#    points    => "300,100 300,500",
#    stroke    => '#600',
# );
# # set it as PGM
# $image->Set(magick=>'pgm');

#your pgm is loaded here, now change it to gif or whatever
$image->Set(magick=>'gif');
my $blob = $image->ImageToBlob();

# Tk wants base64encoded images
my $content = encode_base64( $blob ) or die $!;

my $mw  = MainWindow->new();
my $tkimage = $mw->Photo(-data => $content);
# $mw->Label(-image => $tkimage)->pack(-expand => 1, -fill => 'both');
# $mw->Label(-image => $tkimage)->pack(-expand => 1, -fill => 'both');
$mw->Label(-image => $tkimage)->pack(-side => "right");
$mw->Label(-image => $tkimage)->pack(-side => "right");
$mw->Button(-text => 'Quit', -command => [destroy => $mw])->pack;

MainLoop;

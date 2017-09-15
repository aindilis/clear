#!/usr/bin/perl -w

# take a text and fetch all the appropriate images, extracting all the
# concepts

use PreVis;

use File::Slurp;

my $previs = PreVis->new;

# give it a sample text

my $sampletext = read_file("/var/lib/myfrdcsa/codebases/internal/digilib/data/google-books/books/temp.txt");

$previs->Process
  (Text => $sampletext);

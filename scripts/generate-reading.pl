#!/usr/bin/perl -w

use Clear::ReadList;
use CoAuthor::Depends;

use Data::Dumper;

# this program takes a user's knowledge model, a set of new
# unprocessed documents, and a set of content objectives, and
# generates a reading list

my $r = Clear::ReadList->new();
my $d = CoAuthor::Depends->new;

my @dirs = (
	    "/var/lib/myfrdcsa/codebases/internal/digilib/data/security",
	   );

# get a list of the files

foreach my $dir (@dirs) {
  foreach my $f (split /\n/, `find $dir`) {
    if (-f $f) {
      $r->Add($f);
    }
  }
}

foreach my $doc (values %{$r->Documents}) {
  print $doc->OriginalFile."\n";
  $doc->Parse
    (Zipped => 0);
}

# now take all the voy files, unzip them, and run them through the
# CoAuthor::Depends;

my @files;
foreach my $doc (values %{$r->Documents}) {
  if (-f $doc->VoyFile) {
    push @files, $doc->VoyFile;
  }
}

$d->Execute(Files => \@files);

# now with the dependency information saved in /tmp/prerequisites,
# copy it over and run best.pl to generate the jpg, 

# convert all non-voys into voys

# use CoAuthor::Depends to generate dependency graph

# generate the reading list from this graph

# subtract previously read content

# prune for efficiency

# compute ratings of knowledge area

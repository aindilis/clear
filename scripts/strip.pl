#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

use HTML::Strip;

my $hs = HTML::Strip->new();

my $c = read_file($ARGV[0]);
my $clean_text = $hs->parse( $c );
$hs->eof;

print $clean_text."\n";

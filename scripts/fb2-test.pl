#!/usr/bin/perl -w

use Data::Dumper;
use EBook::FB2;

# process some books for testing, especially for use as input to CLEAR
# - to strip the XML formatting, etc.

my $fb2 = EBook::FB2->new;
$fb2->load("temp.fb2");

use EBook::FB2::Body;

foreach my $body ($fb2->bodies()) {

}

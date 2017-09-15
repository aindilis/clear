#!/usr/bin/perl -w

# if (0) {
#   use Math::GSL;
#   use Math::GSL::RNG;

#   my $rng = Math::GSL::RNG->new;

#   while (1) {
#     print gsl_ran_logarithmic($rng, 0.01)."\n";
#   }
# }

sub ChooseRandomFavoringFirst {
  my (%args) = @_;
  my $total1;
  my $factor = 10;
  foreach my $i (1..$args{Count}) {
    $total1 += $factor;
    $factor *= $args{Decay};
  }
  my $cutoff = rand($total1);

  my $factor = 10;
  my $total2;
  foreach my $i (1..$args{Count}) {
    $total2 += $factor;
    $factor *= $args{Decay};
    if ($total2 > $cutoff) {
      return $i;
    }
  }
}

while (1) {
  print ChooseRandomFavoringFirst
    (
     Count => 30,
     Decay => 0.9
    )."\n";
}

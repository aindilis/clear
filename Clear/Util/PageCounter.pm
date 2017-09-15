package Clear::Util::PageCounter;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Contents PageNos /

  ];

sub init {
  my ($self,%args) = @_;
  $self->PageNos([]);
  $self->PageNos->[0] = '';
  $self->Contents($args{Contents});
}

sub ComputePageNumbers {
  my ($self,%args) = @_;
  my $size = scalar @{$self->Contents};
  my $pageno = 0;
  my $i;
  foreach my $i (1 .. $size) {
    if (defined $self->Contents->[$i]) {
      my @items = $self->Contents->[$i] =~ /(.*?)()(.*?)/sg;
      my $newpages = (scalar @items) / 3;
      $pageno += $newpages;
    }
    $self->PageNos->[$i] = $pageno;
  }
}

1;

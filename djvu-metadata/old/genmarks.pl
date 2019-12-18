use v5.024;

my $offs = 0;
say "(bookmarks";
while(<>) {
  chomp;
  if ($_ =~ /^OFFSET (-?\d+)/) {
     $offs = $1; 
     next;
  }

  m{^\s*(\w+)\s+(.*)$};
  my $pno = $1 + $offs;
  say qq/ ("$2" "#$pno")/;
}
say ")";

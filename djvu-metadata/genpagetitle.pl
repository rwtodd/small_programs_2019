use 5.024;

my $pn = 0;
my $repl = 0;
my $numeric = 0;

sub set_page {
  my $pfx = "";
  $pfx = "p" if ($numeric == 1);
  say qq/select $pn; set-page-title "$pfx$repl"/;
  $pn++; $repl++ if ($numeric == 1);
}

while(<>) { 
   m:^(\d+)\s*(.*):;
   if($numeric == 1) {
     while($pn < $1) {
       set_page();
     }
   }
   $pn = $1;
   $repl = $2;
   if($repl =~ m{^\d+$}) { $numeric = 1 } else { $numeric = 0 };
   set_page();
}

say "set-outline marks.dsed"

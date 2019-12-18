#!/usr/bin/env perl

use v5.028;

my (@metadata, @bookmarks, @djvu_pages, %all_pages);

while(<>) {
  chomp;
  next if /^\s*#|^\s*$/;
  if (/^\s*[Mm]eta\s+([^:]+):\s+(.*?)\s*$/) {
     push @metadata, "$1\t$2"
  } elsif (/^\s*[Dd]jvu\s+(\d+)\s+(?:=|is)\s+[Bb]ook\s+(\S*?)(\d*)\s*$/) {
     push @djvu_pages, { djvu => $1, prefix => $2, number => $3  }
  } elsif (/^(\S+)\s+(.*?)\s*$/) {
     push @bookmarks, { page => $1, title => $2 }
  } else {
    die "Bad line: <$_>";
  }
}

if (@djvu_pages) {
  # generate %all_pages during output
  my $prev;
  foreach my $cur (@djvu_pages) {
    if($prev) {
       die "djvu pages out of order! (on $cur->{djvu})" if $prev->{djvu} >= $cur->{djvu};
       while($prev->{djvu} < $cur->{djvu}) {
          my $pno = "$prev->{prefix}$prev->{number}";
          say qq/select $prev->{djvu}; set-page-title "$pno"/;
          $all_pages{$pno} = $prev->{djvu};
          $prev = next_page($prev)
       }
    }     
    my $pno = "$cur->{prefix}$cur->{number}";
    say qq/select $cur->{djvu}; set-page-title "$pno"/;
    $all_pages{$pno} = $cur->{djvu};
    $prev = next_page($cur)
  }
}

if (@metadata) {
  say "select; set-meta";
  say foreach @metadata;
  say "."
}

if (@bookmarks) {
  say "select; set-outline\n(bookmarks";
  foreach my $mark (@bookmarks) {
    my $dp = $all_pages{$mark->{page}} // 
             ($mark->{page} =~ /^\d+$/ and $mark->{page}) or 
             die "Page for bookmark <<$mark->{title}>>, <<$mark->{page}>> not found!"; 
    say qq/("$mark->{title}" "#$dp")/
  }
  say ")\n."
}

sub next_page {
  my $page = shift;
  { djvu => $page->{djvu}+1, 
    prefix => $page->{prefix}, 
    number => ($page->{number} or 1) + 1 }
}

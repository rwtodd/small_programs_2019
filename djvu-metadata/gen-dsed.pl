#!/usr/bin/env perl

use v5.28;
use feature 'refaliasing';
no warnings 'experimental::refaliasing';

my (@metadata, @bookmarks, @djvu_pages, %all_pages);

while(<>) {
  chomp;
  next if /^\s*#|^\s*$/;
  if (/^\s*meta\s+([^:]+):\s+(.*?)\s*$/i) {
     push @metadata, "$1\t$2"
  } elsif (/^\s*djvu\s+(\d+)\s+(?:=|is)\s+book\s+(\S*?)(\d*)\s*$/i) {
     push @djvu_pages, { djvu => $1, prefix => $2, number => $3  }
  } elsif (/^(\S+)\s+(.*?)\s*$/) {
     push @bookmarks, { page => $1, title => $2 }
  } else {
    die "Bad line: <$_>";
  }
}

if (@djvu_pages) {
  # generate %all_pages during output
  my %prev;
  foreach \my %cur (@djvu_pages) {
    if(%prev) {
       die "djvu pages out of order! (on $cur{djvu})" if $prev{djvu} > $cur{djvu};
       \%prev = register_page(\%prev) while $prev{djvu} < $cur{djvu};
    }     
    \%prev = register_page(\%cur)
  }
}

if (@metadata) {
  local $,="\n";
  say "select; set-meta", @metadata, ".";
}

if (@bookmarks) {
  say "select; set-outline\n(bookmarks";
  foreach \my %mark (@bookmarks) {
    my $dp = $all_pages{$mark{page}} // 
             ($mark{page} =~ /^\d+$/ and $mark{page}) or 
             die "Page for bookmark <<$mark{title}>>, <<$mark{page}>> not found!"; 
    say qq/("$mark{title}" "#$dp")/
  }
  say ")\n."
}

# writes out the page title, saves the page to %all_pages, and returns the next page.
sub register_page {
  \my %page = shift;
  my ($pno, $djvu) = ("$page{prefix}$page{number}", $page{djvu});
  say qq/select $djvu; set-page-title "$pno"/;
  $all_pages{$pno} = $djvu;
  { djvu => $page{djvu}+1, 
    prefix => $page{prefix}, 
    number => ($page{number} or 1) + 1 }
}

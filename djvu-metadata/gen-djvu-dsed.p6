grammar DjVuMarks {
   token TOP { ^ <line>* $ }
   token line { [ <mark> || <pageno> || <meta> ] \n }
   token pageno { :i DJVU \s+ (\d+) \s+ \= \s+ BOOK \s+ (<graph>+:) [\s+ PREFIX \s+ (<graph>+:)]? \N* }
   token meta   { :i META \s+ (\w+)\: \s+ (\N+) }
   token mark { (\d+) \s+ (\N+) }
} 

my $offset = 0;       # current difference between book page nums and djvu pages
my $numeric = False;  # are we currently tracking arabic numeral pages?
my $djvu-page = 0;    # the last noted djvu page number
my $book-page = 0;    # the last noted book page number
my $prefix = "p";     # prefix to put on numeric pages

my $marks-file = Nil;
my $pages-file = Nil;
my $meta-file = Nil;

sub gen-page-title() {
   my $pfx = $numeric ?? $prefix !! '';
   $pages-file.say(qq/select {$djvu-page}; set-page-title "{$pfx}{$book-page}"/);
   ++$djvu-page; ++$book-page if $numeric;
}

sub create-marks-file () {
   $marks-file = open 'marks.dsed', :w;
   $marks-file.say('(bookmarks');
}

sub MAIN(Str $fn where *.IO.f) {
   my $result = DjVuMarks.parse($fn.IO.slurp);
   die "Could not parse the input!" unless $result;

   $pages-file = open 'pages.dsed', :w;
   for $result<line> {
     when .<meta> { 
        $meta-file = open 'meta.dsed', :w unless $meta-file;
        $meta-file.say(qq/{$_<meta>[0]}\t"{$_<meta>[1]}"/)
     }
     when .<mark> { 
        create-marks-file() unless $marks-file;
        $marks-file.say(qq/("{$_<mark>[1]}" "#{$_<mark>[0]+$offset}")/)
     }
     when .<pageno> { 
        my ($djvuno, $bookno, $npfx) = map *.Str, @($_<pageno>);
        if $numeric {
           while $djvu-page < $djvuno {
               gen-page-title()
           }
        }
        $numeric = $bookno ~~ /^ \d+ $/;
        $djvu-page = $djvuno;
        $book-page = $bookno;
        $prefix = $npfx // 'p';
        $offset = $numeric ?? $djvuno - $bookno !! 0;
        gen-page-title()
     }
  }
  if $meta-file {
    $pages-file.say('select; set-meta meta.dsed');
    $meta-file.close;
  }
  if $marks-file { 
    $pages-file.say('select; set-outline marks.dsed');
    $marks-file.say(')');
    $marks-file.close;
  }
  $pages-file.close;
}

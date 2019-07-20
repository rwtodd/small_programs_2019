grammar DjVuMarks {
   token TOP { <line>* \s* }
   token ws { \h* }
   token line { \s*: [ <mark> || <pageno> || <meta> || <comment> || .<error()> ] \h*\n }
   token comment { '#' \N+ }
   rule pageno { :i 'DJVU' (\d+) ['=' || 'IS'] 'BOOK' (<graph>+:) ['PREFIX' (<graph>+:)]? }
   rule meta { :i 'META' (\w+:)':' (\N+:) }
   rule mark { (\d+) (\N+) }
   method error() {
      my $parsed-so-far = self.target.substr(0, self.pos);
      die "Cannot parse input on line $parsed-so-far.lines.elems()"
   }
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
           if $djvu-page >= $djvuno { die "Djvu page $djvuno is <= the previously-mentioned page $djvu-page!" }
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

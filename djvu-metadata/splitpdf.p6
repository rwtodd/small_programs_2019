my $gs = 'C:\Program Files\gs\gs9.24\bin\gswin64c.exe';  # location on my machine

sub USAGE() {
  print Q:to/EOH/;

Usage: perl splitpdf.pl [options] <pdf>
  --test=nn: only convert page nn, for dpi testing
  --dpi=nn: use dpi nn (default 600)
  --unit=nn: split into units of nn pages (default 50)

This program splits a pdf into mutliple TIFF files (24bit color, lzw-compressed).
EOH
}

sub MAIN(Str $pdf where *.IO.f, Int :test($testing), Int :$unit=50, Int :$dpi=600) {
  my $pages = get-page-count($pdf);
  say "PDF has $pages pages."; 
  
  if $testing.defined {
    say "We are testing on page $testing at $dpi DPI.";
    generate-tiff($pdf, $dpi, $testing, $testing);
    exit 0;
  }

  say "Converting $unit pages at a time at $dpi DPI.";
  loop (my $fp = 1; $fp <= $pages; $fp += $unit) {
    generate-tiff($pdf, $dpi, $fp, $fp + $unit - 1)
  }
}

sub get-page-count($fn) {
  qqx{wsl pdfinfo $fn} ~~ rx/^^ 'Pages:' \s+ (\d+)/ or die "Can't determine pdf pages!";
  +$0
}

sub generate-tiff($fn, $dpi, $fp, $lp) {
  my $ofile = sprintf('page-%04d.tiff', $fp);
  run $gs, '-sDEVICE=tiff24nc', "-dFirstPage=$fp", "-dLastPage=$lp", "-r{$dpi}x{$dpi}", '-o', $ofile, $fn
     unless $ofile.IO.f;
}

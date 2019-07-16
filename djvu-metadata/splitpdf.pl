use 5.024;
use Getopt::Std qw/getopts/;
$Getopt::Std::STANDARD_HELP_VERSION = 1;  # exit on help/version
our $VERSION = "1.0a";

sub HELP_MESSAGE {
  say <<EOH;

usage: perl splitpdf.pl [options] <pdf> 
  -t nn: only convert page nn, for dpi testing
  -d nn: use dpi nn (default 600)
  -u nn: split into units of nn pages (default 50)

This program splits a pdf into mutliple TIFF files (24bit color, lzw-compressed).
EOH
}

my %opts = ( d => 600, s => 50 );  # default values
getopts('t:d:s:', \%opts) or die 'Bad options!';
my ($dpi, $unit, $pdf) =  ( @opts{'d','s'}, shift @ARGV );
my $pages = get_pdf_pages($pdf);

if(defined $opts{t}) {
  say "Testing page $opts{t} at $dpi dpi";
  generate_tiff($opts{t}, $opts{t});
  exit 0;
}

say "Converting $pages pages at $dpi dpi, $unit pages at a time.";
for(my $fp = 1; $fp <= $pages; $fp += $unit) {
   generate_tiff($fp, $fp + $unit - 1);
}

# call out to pdfinfo (poppler-tools) to get the number of pages
sub get_pdf_pages {
   my $doc = shift;
   my $info = `pdfinfo $doc`;
   $info =~ m/^Pages:\s+(\d+)/m or die "Could not determine number of pages...";
   return +$1;
}

# call out to ghostscript to generate the actual tiff
sub generate_tiff {
   my ($fp, $lp) = @_; 
   my $ofile = sprintf('page-%04d.tiff',$fp);
   system("gs -sDEVICE=tiff24nc -dFirstPage=$fp -dLastPage=$lp -r${dpi}x${dpi} -o ${ofile} '$pdf'")
      unless (-f $ofile);
}

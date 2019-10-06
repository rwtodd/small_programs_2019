# gen-dsed

A Clojure version of the djvused-generation program.  There are several variants in
this repository, with similar capabilities (in Perl6, Powershell, haskell, etc). As
of this writing, this Clojure version is the most advanced.

## Usage

    $ java -jar gen-dsed-1.0.0-standalone.jar infile

## Input Format Example

    # You can make comments like this
    # Here's some metadata to put into the djvu file:
    meta Title: A book title
    meta Author: whoever it is
    meta Date:  1980

    # Here are table-of-contents entries (bookmarks):

    # Raw numbers are pages in the djvu file:
    1 Cover
    5 Preface

    # Numbers with a prefix generally represent page numbers as
    # they appear on the book pages (e.g., when it is scanned)
    p1 Chapter 1
    p27 Chapter 2
    p99 Chapter 3

    # Now, we need to map raw djvu pages to book page-numbers:
    djvu 8 is book p1
    #   (the tool will fill in p2, p3, etc. until the next entry)
    djvu 101 is book back

... and the resulting djvused file will:

  * set the page titles to match the book page numbers
  * set an outline with all the bookmarks given
  * set the djvu metadata with the data provided

## License

MIT licensed

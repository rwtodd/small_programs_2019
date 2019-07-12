# djvu metadata scripts

These are just some perl scripts to help automate setting the metadata on scanned DjVu books.

iOS readers don't understand outlines that reference page titles.  So, I must outline with page numbers only. To help
with that, perl will track an offset amount.  In this way, I can refer to the page with "32" on it even though it is 21 document pages later than that in the document itself:

~~~~~
OFFSET 21
32   Chapter A
130 Chapter B
~~~~~

~~~~~
perl ~/bin/genmarks.pl < marks.txt > marks.dsed
~~~~~

The output _must_ be called marks.dsed, because pages.dsed refers to it below.

Then, I can set the page titles to refer to the numbers printed on the pages. When using plain numbers, 
the perl script will fill in the gaps in numbering for me:
 
~~~~~
3 ix
4 x
5 1
205 199
~~~~~

perl ~/bin/genpagetitle.pl < pages.txt > pages.dsed  # N.B. also sets the marks in the file.

Now set them:

    djvused -f pages.dsed -s mybook.djvu


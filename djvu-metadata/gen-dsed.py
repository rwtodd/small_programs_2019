#!/usr/bin/env python

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate djvused input for book metadata
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
from collections import namedtuple
import re
import itertools
import sys
import io

BookMark = namedtuple('BookMark', ['title', 'book_page'])
DjvuPage = namedtuple('DjvuPage', ['djvu', 'prefix', 'number'])

metadata = list()   # list of metadata strings
bookmarks = list()  # list of BookMarks
djvu_pages = list() # list of DjvuPage

# Pre-compile the regexps ...
comments_line = re.compile('^\s*#|^\s*$')
metadata_line = re.compile('^\s*[Mm]eta\s+([^:]+):\s+(.*?)\s*$')
djvu_line = re.compile('^\s*[Dd]jvu\s+(\d+)\s+(?:=|is)\s+[Bb]ook\s+(\S*?)(\d*)\s*$')
bookmark_line = re.compile('^(\S+)\s+(.*?)\s*$')

def parse_line(l : str) -> None:
    match = None
    if comments_line.match(l):
        pass
    elif match := metadata_line.match(l):
        metadata.append(match.expand('\\1\t\\2'))
    elif match := djvu_line.match(l):
        djvu,prefix,number = int(match.group(1)), match.group(2), match.group(3)
        number = number and int(number)
        djvu_pages.append(DjvuPage(djvu, prefix, number))
    elif match := bookmark_line.match(l):
        bookmarks.append(BookMark(title=match.group(2), book_page=match.group(1)))
    else:
        raise RuntimeError(f"Bad line <{l}>!!")

def generate_all_pages() -> dict:
    """Generate a map from book pages to djvu pages, for all pages in the book"""
    result = dict()
    def add_page(p: DjvuPage) -> None:
        result[f"{p.prefix}{p.number}"] = p.djvu
    def next_page(page : DjvuPage) -> DjvuPage:
        d,p,n = page
        return DjvuPage(d + 1, p, (n or 1) + 1)
    p1,p2 = itertools.tee(djvu_pages,2)
    if djvu_pages: next(p2)
    for startp,endp in itertools.zip_longest(p1,p2,fillvalue=None):
        if endp:
            if startp.djvu >= endp.djvu: raise RuntimeError(f"{startp} is after {endp}!")
            while startp.djvu < endp.djvu:
                add_page(startp)
                startp = next_page(startp)
        else:
            add_page(startp)
    return result

try:
    with io.open(sys.argv[1]) as infile:
        for l in infile.readlines():
            parse_line(l)
    all_pages = generate_all_pages()
    if metadata:
        print('select; set-meta', *metadata, '.', sep='\n')
    if bookmarks:
        print('select; set-outline','(bookmarks', sep='\n')
        for mark in bookmarks:
            dpage = all_pages.get(mark.book_page,None)
            if not dpage:
                if mark.book_page.isnumeric(): dpage = mark.book_page
                else: raise RuntimeError(f"bookmark {mark} not found!")
            print(f'("{mark.title}" "#{dpage}")')
        print(')','.', sep='\n')        
    if all_pages:
        for bp,dp in all_pages.items():
            print(f'select {dp}; set-page-title "{bp}"')
except Exception as e:
    print(e, file=sys.stderr)
    print('Usage: gen-dsed <infile>', file=sys.stderr)
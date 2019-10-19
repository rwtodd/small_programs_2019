using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Linq;

namespace GenDSed
{
    internal struct BookPage
    {
        internal readonly string Prefix { get; }
        internal readonly int? PageNo { get; }
        internal BookPage(string t, int? pn = null) { Prefix = t; PageNo = pn; }
        internal BookPage Next() => new BookPage(Prefix, (PageNo ?? 1) + 1);
        public override string ToString() =>
            String.Format("{0}{1}", Prefix, (PageNo == null) ? "" : PageNo.ToString());

        public override bool Equals(object? obj) =>
            obj is BookPage bp && 
            Prefix.Equals(bp.Prefix) && 
            PageNo == bp.PageNo;

        public override int GetHashCode() => base.GetHashCode();
    }

    internal struct DjvuPage
    {
        internal readonly int DocPage { get; }
        internal readonly BookPage BookPage { get; }

        internal DjvuPage(int dp, BookPage bp)
        {
            DocPage = dp;
            BookPage = bp;
        }

        internal DjvuPage Next() => new DjvuPage(DocPage + 1, BookPage.Next());
    }

    internal struct BookMark
    {

        internal readonly BookPage BookPage { get; }
        internal readonly string Title { get; }

        internal bool IsRawPage() => BookPage.Prefix.Length == 0;

        internal BookMark(string prefix, int? pno, string markTitle)
        {
            BookPage = new BookPage(prefix, pno);
            Title = markTitle;
        }
    }

    internal struct MatchedBookMark
    {
        internal readonly int DocPage { get; }
        internal readonly BookMark Mark { get; }

        internal MatchedBookMark(int docPage, BookMark mark)
        {
            DocPage = docPage;
            Mark = mark;
        }
    }

    internal class InputLines
    {

        internal Dictionary<string, string> MetaInfo { get; }
        internal List<BookMark> BookMarks {get; }
        internal List<DjvuPage> DocPages {  get; }

        private readonly Regex cmtPattern;
        private readonly Regex metaPattern;
        private readonly Regex djvuPattern;
        private readonly Regex markPattern;

        /**
         * Constructs an empty {@code InputLines} instance.
         */
        internal InputLines()
        {
            MetaInfo = new Dictionary<string, string>();
            BookMarks = new List<BookMark>();
            DocPages = new List<DjvuPage>();
            cmtPattern = new Regex(@"^\s*$|^\s*#.*$");
            metaPattern = new Regex(@"^\s*[Mm][Ee][Tt][Aa]\s+([^:]+):\s*(.*)$");
            djvuPattern = new Regex(@"^\s*[Dd][Jj][Vv][Uu]\s+(\d+)\s+(?:Is|is|=)(?:\s+[Bb][Oo][Oo][Kk])?\s+(\S*?)(\d*)\s*$");
            markPattern = new Regex(@"^\s*(\S*?)(\d*)\s+(.+)$");
        }

        internal void ParseLine(string s)
        {
            if (cmtPattern.IsMatch(s))
            {
                return; // skip comments
            }

            var m = metaPattern.Match(s);
            if (m.Success)
            {
                MetaInfo.Add(m.Groups[1].Value, m.Groups[2].Value);
                return;
            }

            m = djvuPattern.Match(s);
            if (m.Success)
            {
                int pno = Int32.Parse(m.Groups[1].Value);
                String bookpStr = m.Groups[3].Value;
                int? bookp = null;
                if (bookpStr.Length > 0)
                {
                    bookp = Int32.Parse(bookpStr);
                }
                DocPages.Add(new DjvuPage(pno, new BookPage(m.Groups[2].Value, bookp)));
                return;
            }

            m = markPattern.Match(s);
            if (m.Success)
            {
                int? bookp = null;
                String bookpStr = m.Groups[2].Value;
                if (bookpStr.Length > 0)
                {
                    bookp = Int32.Parse(bookpStr);
                }

                BookMarks.Add(new BookMark(m.Groups[1].Value, bookp, m.Groups[3].Value));
                return;
            }

            throw new FormatException(String.Format("Bad input <{0}>!", s));
        }
    }

    static class Program
    {
        private static List<DjvuPage> AllPages(List<DjvuPage> inputs)
        {
            var result = new List<DjvuPage>();

            var pages = inputs.GetEnumerator();
            if(!pages.MoveNext()) return result;

            var current = pages.Current;
            while(pages.MoveNext())
            {
                var tgt = pages.Current;
                while(current.DocPage < tgt.DocPage)
                {
                    result.Add(current);
                    current = current.Next();
                }
                current = tgt;
            }
            result.Add(current);
            return result;
        }

        private static List<MatchedBookMark> MatchMarks(
            List<DjvuPage> pages,
            List<BookMark> marks)
        {
            var result = new List<MatchedBookMark>(marks.Count);
            var pageIdx = 0;
            var lastIdx = pages.Count;

            foreach (var mark in marks)
            {
                if (mark.IsRawPage())
                {
                    // raw pages match themselves... no lookup required
                    result.Add(new MatchedBookMark(mark.BookPage.PageNo ?? 1, mark));
                }
                else
                {
                    // the mark is for a titled page, so search the `pages` list
                    // for the matching enty.
                    for (; pageIdx < lastIdx; ++pageIdx)
                        if (pages[pageIdx].BookPage.Equals(mark.BookPage))
                            break;

                    // at this point, either a match was found, or it is an error.
                    if (pageIdx < lastIdx)
                    {
                        result.Add(new MatchedBookMark(pages[pageIdx].DocPage, mark));
                    }
                    else
                    {
                        throw new ArgumentException(
                                String.Format("Unmatched bookmark {0}!",
                                        mark.BookPage.ToString()));
                    }
                }
            }
            return result;
        }

        private static void OutputMeta(System.IO.StreamWriter wtr,
            Dictionary<string, string> metas)
        {
            if (metas.Count == 0)
            {
                return;
            }
            wtr.WriteLine("select; set-meta");
            foreach (var e in metas)
            {
                wtr.WriteLine("{0}\t\"{1}\"", e.Key, e.Value);
            }
            wtr.WriteLine(".");
        }

        private static void OutputMarks(System.IO.StreamWriter wtr,
           List<MatchedBookMark> marks)
        {
            if (marks.Count == 0)
            {
                return;
            }
            wtr.WriteLine("select; set-outline");
            wtr.WriteLine("(bookmarks");
            foreach (var m in marks)
            {
               wtr.WriteLine("(\"{0}\" \"#{1}\")",
                    m.Mark.Title,
                    m.DocPage);
            }
            wtr.WriteLine(")");
            wtr.WriteLine(".");
        }

        private static void OutputPages(System.IO.StreamWriter wtr,
            List<DjvuPage> pages)
        {
            foreach (var pg in pages)
            {
                wtr.WriteLine("select {0}; set-page-title \"{1}\"",
                    pg.DocPage,
                    pg.BookPage);
            }
        }


        static void Main(string[] args)
        {
            if(args.Length == 0)
            {
                var oldColor = Console.ForegroundColor;
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.Error.WriteLine("Usage: gen-dsed <infile>");
                Console.ForegroundColor = oldColor;
                Environment.Exit(1);
            }

            var inl = new InputLines();
            foreach(var line in System.IO.File.ReadLines(args[0]))
            {
                inl.ParseLine(line);
            }
            using (var ofile = System.IO.File.CreateText(args[0] + ".dsed"))
            {
                var allPages = AllPages(inl.DocPages);
                var matched = MatchMarks(allPages, inl.BookMarks);
                OutputPages(ofile, allPages);
                OutputMeta(ofile, inl.MetaInfo);
                OutputMarks(ofile, matched);
            }

        }
    }
}

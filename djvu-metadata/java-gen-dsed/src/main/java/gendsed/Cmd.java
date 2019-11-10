package gendsed;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * A BookPage represents a string prefix+number, as in "p121".
 * 
 * @author Richard Todd
 *
 */
final class BookPage {

    final String prefix;
    final Integer page;

    BookPage(int pg) {
        this("", pg);
    }

    BookPage(String pre) {
        this(pre, null);
    }

    BookPage(String pre, Integer bpg) {
        prefix = pre;
        page = bpg;
    }

    BookPage next() {
        return new BookPage(prefix, (page == null) ? 2 : (page + 1));
    }

    @Override
    public int hashCode() {
        int hash = 3;
        hash = 13 * hash + Objects.hashCode(this.prefix);
        hash = 13 * hash + Objects.hashCode(this.page);
        return hash;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final BookPage other = (BookPage) obj;
        if (!Objects.equals(this.prefix, other.prefix)) {
            return false;
        }
        if (!Objects.equals(this.page, other.page)) {
            return false;
        }
        return true;
    }

    
    @Override
    public String toString() {
        return String.format("%s%s", prefix, (page == null) ? "" : page.toString());
    }
}

final class DjvuPage {

    final int djvuPage;
    final BookPage bookPage;

    DjvuPage(int dp, BookPage bp) {
        djvuPage = dp;
        bookPage = bp;
    }

    DjvuPage next() {
        return new DjvuPage(djvuPage + 1, bookPage.next());
    }
}

final class BookMark {

    final BookPage bookPage;
    final String title;

    boolean isRawPage() {
        return bookPage.prefix.isEmpty();
    }

    BookMark(String prefix, Integer pno, String markTitle) {
        bookPage = new BookPage(prefix, pno);
        title = markTitle;
    }
}

final class MatchedBookMark {
    final int djvuPage;
    final BookMark mark;

    MatchedBookMark(int djvuPage, BookMark mark) {
        this.djvuPage = djvuPage;
        this.mark = mark;
    }
}

/**
 * InputLines parses and sorts the user input into categories.  The types of
 * input supported are: Comments, Metadata, Djvu Page Titles, and Bookmarks.
 * @author Richard Todd
 */
final class InputLines {

    final HashMap<String, String> metaInfo;
    final ArrayList<BookMark> bookmarks;
    final ArrayList<DjvuPage> djvuPages;
    final Pattern cmtPattern = Pattern.compile("^\\s*$|^\\s*#.*$");
    final Pattern metaPattern = Pattern.compile("^\\s*[Mm][Ee][Tt][Aa]\\s+([^:]+):\\s*(.*)$");
    final Pattern djvuPattern = Pattern.compile("^\\s*[Dd][Jj][Vv][Uu]\\s+(\\d+)\\s+(?:Is|is|=)(?:\\s+[Bb][Oo][Oo][Kk])?\\s+(\\S*?)(\\d*)\\s*$");
    final Pattern markPattern = Pattern.compile("^\\s*(\\S*?)(\\d*)\\s+(.+)$");

    /**
     * Constructs an empty {@code InputLines} instance.
     */
    InputLines() {
        metaInfo = new HashMap<>();
        bookmarks = new ArrayList<>();
        djvuPages = new ArrayList<>();
    }

    void parseLine(String s) throws IllegalArgumentException {
        if (cmtPattern.matcher(s).matches()) {
            return; // skip comments
        }

        var m = metaPattern.matcher(s);
        if (m.matches()) {
            metaInfo.put(m.group(1), m.group(2));
            return;
        }

        m = djvuPattern.matcher(s);
        if (m.matches()) {
            int pno = Integer.parseInt(m.group(1));
            String bookpStr = m.group(3);
            Integer bookp = null;
            if (!bookpStr.isEmpty()) {
                bookp = Integer.parseInt(bookpStr);
            }
            djvuPages.add(new DjvuPage(pno, new BookPage(m.group(2), bookp)));
            return;
        }

        m = markPattern.matcher(s);
        if (m.matches()) {
            Integer bookp = null;
            String bookpStr = m.group(2);
            if (!bookpStr.isEmpty()) {
                bookp = Integer.parseInt(bookpStr);
            }

            bookmarks.add(new BookMark(m.group(1), bookp, m.group(3)));
            return;
        }

        throw new IllegalArgumentException(String.format("Bad input <%s>!", s));
    }
}

/**
 * This is the main driver for the gen-dsed program (Java version).
 * @author Richard Todd
 */
public class Cmd {

    /**
     * Write djvused-formatted output for the provided metadata.
     * @param out the output stream
     * @param metas the metadata to output
     */
    private static void outputMeta(final PrintWriter out,
            final HashMap<String, String> metas) {
        if (metas.isEmpty()) {
            return;
        }
        out.printf("select; set-meta%n");
        for (final var e : metas.entrySet()) {
            out.printf("%s\t\"%s\"%n", e.getKey(), e.getValue());
        }
        out.printf(".%n");
    }

    
    /**
     * Write djvused-formatted output for {@code MatchedBookMark} objects.
     * @param out the output stream
     * @param marks the bookmarks to output.
     */
    private static void outputMarks(final PrintWriter out,
            final ArrayList<MatchedBookMark> marks) {
        if (marks.isEmpty()) {
            return;
        }
        out.printf("select; set-outline%n(bookmarks%n");
        for (final var m : marks) {
            out.printf("(\"%s\" \"#%d\")%n",
                    m.mark.title,
                    m.djvuPage);
        }
        out.printf(")%n.%n");
    }

    /**
     * Write djvused-formatted output for {@code DjvuPage} objects.
     * @param out the output stream
     * @param pages the pages to output
     */
    private static void outputPages(final PrintWriter out,
            ArrayList<DjvuPage> pages) {
        for (final var pg : pages) {
            out.printf("select %d; set-page-title \"%s\"%n",
                    pg.djvuPage,
                    pg.bookPage);
        }
    }

    /**
     * Expand the input list of @{code DjvuPage}s to fill all the gaps in
     * provided pages.  Return the expanded list.
     * @param pages the djvu pages specified in the input file
     * @return a full list of pages
     */
    private static ArrayList<DjvuPage> allPages(ArrayList<DjvuPage> pages) {
        final var result = new ArrayList<DjvuPage>();
        if(pages.isEmpty()) return result;

        var it = pages.iterator();
        var current = it.next();
        while(it.hasNext()) {
            final var target = it.next();
            while(current.djvuPage < target.djvuPage) {
                result.add(current);
                current = current.next();
            }
            current = target;
        }
        result.add(current);        
        return result;
    }

    private static ArrayList<MatchedBookMark> matchMarks(
            final ArrayList<DjvuPage> pages, 
            final ArrayList<BookMark> marks) {
        final var result = new ArrayList<MatchedBookMark>(marks.size());
        var pageIdx = 0;
        final var lastIdx = pages.size();
        
        for(final var mark : marks) {
            if(mark.isRawPage()) {
                // raw pages match themselves... no lookup required
                result.add(new MatchedBookMark(mark.bookPage.page, mark));
            } else {
                // the mark is for a titled page, so search the `pages` list
                // for the matching enty.
                for( ; pageIdx < lastIdx; ++pageIdx) 
                    if(pages.get(pageIdx).bookPage.equals(mark.bookPage))
                        break;
                
                // at this point, either a match was found, or it is an error.
                if(pageIdx < lastIdx) {
                    result.add(new MatchedBookMark(pages.get(pageIdx).djvuPage, mark));
                } else {
                    throw new IllegalArgumentException(
                            String.format("Unmatched bookmark %s!", 
                                    mark.bookPage.toString()));
                }
            }
        }
        return result;
    }
    
    public static void main(String[] args) {
        if(args.length != 1) {
            System.err.println("Usage: gendsed <infile>");
            System.exit(-1);
        }
        
        final var inputs = new InputLines();
        try (final var rdr = Files.newBufferedReader(Paths.get(args[0]))) {
            rdr.lines().forEachOrdered(inputs::parseLine);
        } catch (IOException|IllegalArgumentException e) {
            e.printStackTrace();
            System.exit(-1);
        }

        final var outfn = args[0] + ".desd";
        try (final var out = new PrintWriter(Files.newBufferedWriter(
                Paths.get(outfn),
                StandardOpenOption.WRITE, StandardOpenOption.CREATE))) {
            System.err.println("Writing " + outfn);
            final var allPages = allPages(inputs.djvuPages);
            final var matched = matchMarks(allPages, inputs.bookmarks);
            outputPages(out, allPages);
            outputMeta(out, inputs.metaInfo);
            outputMarks(out, matched);
        } catch (IOException|IllegalArgumentException e) {
            e.printStackTrace();
            System.exit(-1);
        }

    }
}

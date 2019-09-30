module Main where

import qualified System.Environment as Env (getArgs)
import System.IO (Handle, hPutStr, hPutStrLn)
import Data.Char (toUpper)
import Data.Maybe (maybe, isJust, fromJust)
import Control.Monad (when)
import qualified Text.Parsec as P
import Text.Parsec.String (parseFromFile)

-- ############### META-DATA ############################################
data Meta = Meta { meta_key, meta_value :: String }
  deriving Show

dsed_meta m = concat [(meta_key m), "\t", (show . meta_value) m, "\n"]

-- ############### BOOK PAGE TITLES   ###################################
data Page = Page { pg_prefix :: String, pg_number :: Maybe Integer }
   deriving (Show, Eq)

page_str p = concat [ pg_prefix p, maybe "" show (pg_number p) ]

next_page p = p { pg_number = Just $ maybe 2 (+1) (pg_number p) }

-- ############### DJVU PAGE -> BOOK PAGE     ###########################
data DjvuPage = DjvuPage { djvu_pg :: Integer, book_pg :: Page }
   deriving Show

next_djvupg (DjvuPage dp bp) = DjvuPage { djvu_pg = dp+1, book_pg = next_page bp }

dsed_djvu_pg p = concat [ "select ", (show . djvu_pg) p, 
                           "; set-page-title \"", (page_str . book_pg) p, "\"\n" ]

all_pages (d1:d2:ds) | (djvu_pg d1 == djvu_pg d2) = all_pages (d2:ds)
                     | otherwise                  = d1 : all_pages (next_djvupg d1 : d2 : ds)
all_pages other = other

-- ############### TABLE OF CONTENTS ENTRIES    ##########################
data Contents = Contents { contents_pg :: Page, contents_title :: String }
   deriving Show

dsed_contents pgno c =  concat ["(",  (show . contents_title) c, " \"#", (show pgno), "\")\n"]
has_raw_page c = let pg = contents_pg c
                 in (pg_prefix pg == "") && isJust (pg_number pg)

find_contents_pages _       []      = []
find_contents_pages ds      (c1:cs) | has_raw_page c1                = let p = fromJust $ (pg_number . contents_pg) c1
                                                                       in (p, c1) : find_contents_pages ds cs
find_contents_pages (d1:ds) (c1:cs) | (book_pg d1 == contents_pg c1) = (djvu_pg d1, c1) : find_contents_pages ds cs
                                    | otherwise                      = find_contents_pages ds (c1:cs)
find_contents_pages []      cs      = error $ "contents remain w/no pages! " ++ (show cs)


-- ############### PARSING ##############################################
the_end :: P.Parsec String () ()
the_end = (P.many $ P.char ' ') >> 
   ((P.endOfLine >> P.spaces >> return ()) P.<|> P.eof)

rest_of_line :: P.Parsec String () String
rest_of_line = P.manyTill P.anyChar (P.try the_end)

comment :: P.Parsec String () Char
comment = (P.char '#') <* rest_of_line

token :: P.Parsec String () a -> P.Parsec String () a
token tok = P.try (tok <* P.space)

ci_token :: String -> P.Parsec String () String
ci_token word = token $ P.string word P.<|> (P.string $ (toUpper $ head word):(tail word))

meta = ci_token "meta"
djvu = ci_token "djvu"
book = ci_token "book"
equals = token $ P.string "=" P.<|> P.string "is"

page_spec :: P.Parsec String () Page
page_spec = do
  pre <- P.many P.letter
  num <- if (null pre) then (P.many1 P.digit) else (P.many P.digit)
  return Page { pg_prefix = pre, 
                pg_number = case num of
                               [] -> Nothing
                               x  -> Just $ read x }

data Line = MetaLine Meta | PageLine DjvuPage | ContentsLine Contents | CommentLine
   deriving Show

djvu_comment_line :: P.Parsec String () Line
djvu_comment_line = (P.skipMany1 comment) >> return CommentLine 

djvu_meta_line :: P.Parsec String () Line
djvu_meta_line = do
  k <- meta *> (P.many1 P.alphaNum) <* P.char ':' <* P.spaces
  v <- rest_of_line
  return (MetaLine $ Meta { meta_key = k, meta_value = v })

djvu_page_line :: P.Parsec String () Line
djvu_page_line = do
  dp <- djvu *> token (P.many P.digit)
  bp <- equals *> book  *> page_spec <* P.spaces
  return (PageLine $ DjvuPage { djvu_pg = read dp, book_pg = bp })

djvu_contents_line :: P.Parsec String () Line
djvu_contents_line = do
  pg    <- P.spaces *> token page_spec
  title <- P.spaces *> rest_of_line
  return (ContentsLine $ Contents { contents_pg = pg, contents_title = title })

input_lines :: P.Parsec String () [Line]
input_lines = P.spaces *> P.many (djvu_comment_line P.<|> 
                                  djvu_meta_line    P.<|> 
                                  djvu_page_line    P.<|>
                                  djvu_contents_line)

-- pull in the other two files from pages.dsed...
pages_epilogue has_meta has_contents =
  concat [ (if has_meta then "select; set-meta meta.dsed\n" else ""),
           (if has_contents then "select; set-outline marks.dsed\n" else "") ]

generate_output :: [Meta] -> [DjvuPage] -> [Contents] -> IO ()
generate_output pmeta ppages pconts = do
  when has_meta     $ writeFile "meta.dsed"  $ concatMap dsed_meta pmeta
  when has_contents $ writeFile "marks.dsed" $ contents_surround $ concatMap (uncurry dsed_contents) djvu_contents
  writeFile "pages.dsed" $ (concatMap dsed_djvu_pg djvu_pages) ++ (pages_epilogue has_meta has_contents)
   where 
    contents_surround cs = concat ["(bookmarks\n",cs,")\n"]
    djvu_pages           = all_pages ppages
    djvu_contents        = find_contents_pages djvu_pages pconts
    has_meta             = not $ null pmeta
    has_contents         = not $ null pconts

main :: IO ()
main = do
  args   <- Env.getArgs
  let fname = if (null args) then "marks.txt" else head args
  result <- parseFromFile input_lines fname
  case result of
     Left err  -> print err
     Right lst -> generate_output pmeta ppages pconts 
                     where 
                       pmeta =  [ m | (MetaLine m)     <- lst ]
                       ppages = [ p | (PageLine p)     <- lst ]
                       pconts = [ c | (ContentsLine c) <- lst ]


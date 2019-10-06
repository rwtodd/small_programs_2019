(ns gen-dsed.core-test
  (:require [clojure.test :refer :all]
            [gen-dsed.core :refer :all]))

(deftest page-nums-test
  (testing "next-page works"
    (is (= {:number 2 :prefix "middle" :djvu-pg 22}
           (next-page {:djvu-pg 21 :number nil :prefix "middle"})))
    (is (= {:number 2 :prefix "middle" :djvu-pg 101}
           (next-page {:djvu-pg 100 :prefix "middle"})))
    (is (= {:number 22 :prefix "p" :djvu-pg 5097}
           (next-page {:djvu-pg 5096 :number 21 :prefix "p"})))))

(deftest parse-test
  (testing "parses comments"
    (is (= {:type :comment} (parse-input "")))
    (is (= {:type :comment} (parse-input "         ")))
    (is (= {:type :comment} (parse-input "     ")))
    (is (= {:type :comment} (parse-input "# hello ")))
    (is (= {:type :comment} (parse-input "    # hello there"))))
  (testing "parses metadata"
    (is (= {:type :meta :kw "Title" :val "How to Win"}
           (parse-input "meta Title: How to Win")))
    (is (= {:type :meta :kw "Title" :val "How Not to Win"}
           (parse-input "mETa   Title:   How Not to Win  "))))
  (testing "parses bookmarks"
    (is (= {:type :mark :prefix "p" :number 21 :title "Contents"}
           (parse-input "p21 Contents")))
    (is (= {:type :mark :prefix "midpg" :number nil :title "Pictures Pages"}
           (parse-input "midpg   Pictures Pages  ")))
    (is (= {:type :mark :prefix nil :number 12 :title "Preface"}
           (parse-input "12  Preface"))))
  (testing "parses djvu pages"
    (is (= {:type :djvu :djvu-pg 15 :prefix "p" :number 1}
           (parse-input "djvu 15 is book p1")))
    (is (= {:type :djvu :djvu-pg 150 :prefix "back" :number nil}
           (parse-input "djVu 150 =  back")))
    (is (= {:type :djvu :djvu-pg 21 :prefix "mark" :number 140}
           (parse-input "djvu 21 = bOOk mark140")))
    ))
    

(ns gen-dsed.core
  (:require [clojure.java.io :as io])
  (:gen-class))

(def line-specs
  [
   ;; Comment/Blank lines
   { :rx #"^\s*$|^\s*#.*$" :handler (fn [match] {:type :comment}) }

   ;; Meta lines
   { :rx #"^\s*[Mm][Ee][Tt][Aa]\s+([^:]+):\s*(.*)$"
    :handler (fn [[all k v]]
               {:type :meta :kw k :val (.trim v)}) }

   ;; Djvu Pages lines
   { :rx #"^\s*[Dd][Jj][Vv][Uu]\s+(\d+)\s+(?:Is|is|=)(?:\s+[Bb][Oo][Oo][Kk])?\s+(\S*?)(\d*)\s*$"
    :handler (fn [[all djvu pre num]]
               {:type :djvu
                :djvu-pg (read-string djvu)
                :prefix (if (empty? pre) nil pre)
                :number (if (empty? num) nil (read-string num))}) }

   ;; Bookmark lines -- N.B. this one is permissive, so should be last in the list...
   { :rx #"^\s*(\S*?)(\d*)\s+(.+)$"
    :handler (fn [[all pre num name]]
               {:type :mark
                :prefix (if (empty? pre) nil pre)
                :number (if (empty? num) nil (read-string num))
                :title (.trim name)}) }
   ])

(defn parse-input
  "Parse a line of input into data" 
  [line]
  (->> (map (fn [{:keys [rx handler]}]
              (if-let [m (re-matches rx line)]
                (handler m)))
            line-specs)
       (filter identity)
       first))

(defn separate-input
  "Parse each line in `lines` and separate them by type.
  Make sure all lines parse, and throw an IllegalArgumentException if not.
  Returns the input separated into seqs keyed by :meta :djvu and :marks."
  [lines]
  (let [parsed (map parse-input lines)]
    (when (some nil? parsed)
      (throw (IllegalArgumentException. (str "Line " (inc (.indexOf parsed nil)) " didn't parse!"))))
    (group-by :type parsed)))

(defn same-page?
  "Determine if two maps refer to the same page."
  [a b]
  (and (= (:prefix a) (:prefix b))
       (= (:number a) (:number b))))

(defn next-page
  "Return a spec for the next page, given a page."
  [p]
  (-> p (update :number #(inc (or % 1))) (update :djvu-pg inc)))

(defn all-pages
  [djvus]
  (mapcat (fn [pair]
            (if (== 2 (count pair))
              (take-while #(< (:djvu-pg %) (:djvu-pg (second pair))) (iterate next-page (first pair)))
              pair))
          (partition-all 2 1 djvus)))

(defn annotate-bookmarks
  "Associate a djvu-pg with each of the given bookmarks."
  [marks pgs]
  (loop [result (transient [])
         marks  marks
         pgs    pgs]
    (let [mark (first marks),  page (first pgs)]
      (cond (nil? mark)            (persistent! result)
            (nil? (:prefix mark))  (recur (conj! result (assoc mark :djvu-pg (:number mark)))
                                          (rest marks)
                                          pgs)
            (same-page? mark page) (recur (conj! result (assoc mark :djvu-pg (:djvu-pg page)))
                                          (rest marks)
                                          (rest pgs))
            (nil? page)            (throw (Exception. (str "Bookmark " mark " with no matching page!")))
            :else                  (recur result marks (rest pgs))))))
          
(defn meta->dsed
  "Write dsed-formatted output for `ms` (a seq of meta lines) to `out`"
  [out ms]
  (.write out (format "select; set-meta%n"))
  (doseq [{:keys [kw val]} ms] (.write out (format "%s\t\"%s\"%n" kw val)))
  (.write out (format ".%n")))

(defn marks->dsed
  "Write dsed-formatted output for `ms` (a seq of marks lines) to `out`"
  [out ms]
  (.write out (format "select ; set-outline%n(bookmarks%n"))
  (doseq [{:keys [djvu-pg title]} ms]
    (.write out (format "(\"%s\" \"#%d\")%n" title djvu-pg)))
  (.write out (format ")%n.%n")))

(defn pages->dsed
  "Write dsed-formatted output for `ps` (a seq of page titles) to `out`"
  [out ps]
  (doseq [{:keys [djvu-pg number prefix]} ps]
    (.write out (format "select %d; set-page-title \"%s\"%n" djvu-pg
                        (str prefix number)))))

(defn -main
  "takes a single arg (a filename), and produces filename.dsed with
  the associated Djvused commands in it."
  [& args]
  (if-not (= (count args) 1)
    (do (.println *err* "Usage: gen-dsed <filename>")
        (System/exit -1))
    
    (with-open [input (io/reader (first args))]
      (let [{:keys [mark djvu meta]} (separate-input (line-seq input))
            pages                    (all-pages djvu)
            annotated                (annotate-bookmarks mark pages)]
        (with-open [out (io/writer (str (first args) ".dsed"))]
          (pages->dsed out pages)
          (when (seq meta)      (meta->dsed out meta))
          (when (seq annotated) (marks->dsed out annotated)))))))


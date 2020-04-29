(ns gen-dsed.core
  (:require [clojure.java.io :as io])
  (:gen-class))

(def line-specs
  [
   ;; Comment/Blank lines
   { :rx #"^\s*$|^\s*#.*$" :handler (fn [match] {:type :comment}) }

   ;; Meta lines
   { :rx #"(?i)^\s*meta\s+([^:]+):\s*(.*?)\s*$"
    :handler (fn [[all k v]] {:type :meta :kw k :val v}) }

   ;; Djvu Pages lines
   { :rx #"(?i)^\s*djvu\s+(\d+)\s+(?:is|=)(?:\s+book)?\s+(\S*?)(\d*)\s*$"
    :handler (fn [[all djvu pre num]]
               {:type :djvu
                :djvu-pg (read-string djvu)
                :prefix (if (empty? pre) nil pre)
                :number (if (empty? num) nil (read-string num))}) }

   ;; Bookmark lines -- N.B. this one is permissive, so should be last in the list...
   { :rx #"^\s*(\S*?)(\d*)\s+(.+?)\s*$"
    :handler (fn [[all pre num name]]
               {:type :mark
                :numeric (empty? pre)
                :prefix (if (empty? pre) nil pre)
                :number (if (empty? num) nil (read-string num))
                :title name}) }
   ])

(defn- parse-input
  "Parse a line of input into data" 
  [line]
  (some (fn [{:keys [rx handler]}]
          (if-let [m (re-matches rx line)]
            (handler m)))
        line-specs))

(defn- separate-input
  "Parse each line in `lines` and separate them by type.
  Make sure all lines parse, and throw an IllegalArgumentException if not.
  Returns the input separated into seqs keyed by :meta :djvu and :marks."
  [lines]
  (let [parsed (map parse-input lines)]
    (when (some nil? parsed)
      (throw (IllegalArgumentException. (str "Line " (inc (.indexOf parsed nil)) " didn't parse!"))))
    (group-by :type parsed)))

(defn- next-page
  "Return a spec for the next page, given a page."
  [p]
  (-> p (update :number (fnil inc 1)) (update :djvu-pg inc)))

(defn- all-pages
  "Generate a lazy sequence of all pages, given the input `djvus` lines"
  [djvus]
  (->> (partition-all 2 1 djvus)
       (mapcat (fn [[a b]]
                 (let [pages (if b
                               (- (:djvu-pg b) (:djvu-pg a))
                               1)]
                   (if (pos? pages)
                     (take pages (iterate next-page a))
                     (throw (IllegalArgumentException.
                             (format "Djvu pg %d isn't after %d!"
                                     (:djvu-pg b)
                                     (:djvu-pg a))))))))))

(defn- meta->dsed
  "Write dsed-formatted output for `ms` (a seq of meta lines) to `out`"
  [^java.io.BufferedWriter out ms]
  (.write out (format "select; set-meta%n"))
  (doseq [{:keys [kw val]} ms] (.write out (format "%s\t\"%s\"%n" kw val)))
  (.write out (format ".%n")))

(defn- marks->dsed
  "Write dsed-formatted output for `ms` (a seq of marks lines) to `out`, using `all-pgs` for reference"
  [^java.io.BufferedWriter out ms]
  (.write out (format "select; set-outline%n(bookmarks%n"))
  (doseq [mark ms]
    (.write out (format "  (\"%s\" \"#%s\")%n" (:title mark) (:djvu-pg mark))))
  (.write out (format ")%n.%n")))

(defn- match-marks
  "Match bookmarks with the given djvupage, or with itself when they are
  numeric.  Returns [mm, umm]; matched-marks and unmatched-marks"
  ([pg marks accum]
  (let [cur (first marks)]
    (cond (:numeric cur)
          (recur pg (rest marks) (conj accum (assoc cur :djvu-pg (:number cur))))
          (and (= (:number cur) (:number pg))
               (= (:prefix cur) (:prefix pg)))
          (recur pg (rest marks) (conj accum (assoc cur :djvu-pg (:djvu-pg pg))))
          :else [accum marks])))
  ([pg marks]
   (match-marks pg marks [])))

(defn- run-through-pages
  "Print out all the page titles, and during the process, also collect
  a list of matched bookmarks. This is the most complected function in
  the program, and I don't see a better way to define it without
  mutable state."
  [out pgs mrks]
  (let [[mm umm] (match-marks {:prefix "dummy" :number -9999} mrks)]
    (loop [pages   (all-pages pgs)
           marks   umm
           matched (transient [mm])]
      (if (empty? pages)
        (if (empty? marks)
          (apply concat (persistent! matched))
          (throw (Exception. (str "Bookmark <" (:title (first marks)) "> not found!"))))
        (let [pg       (first pages)
              [mm umm] (match-marks pg marks)]
          (.write out (format "select %d; set-page-title \"%s\"%n"
                              (:djvu-pg pg)
                              (str (:prefix pg) (:number pg))))
          (recur (rest pages)
                 umm
                 (if (empty? mm) matched (conj! matched mm))))))))
 
(defn -main
  "takes a single arg (a filename), and produces filename.dsed with
  the associated Djvused commands in it."
  [& args]
  (if-not (= (count args) 1)
    (do (.println ^java.io.PrintWriter *err* "Usage: gen-dsed <filename>")
        (System/exit -1))
    (with-open [input (io/reader (first args))]
      (let [{:keys [mark djvu meta]} (separate-input (line-seq input))
            out-file (str (first args) ".dsed")]
        (.println *err* (str "Writing " out-file)) 
        (with-open [out (io/writer out-file)]
          (let [matched-marks (run-through-pages out djvu mark)]
            (when (seq meta) (meta->dsed out meta))
            (when (seq matched-marks) (marks->dsed out matched-marks))))))))

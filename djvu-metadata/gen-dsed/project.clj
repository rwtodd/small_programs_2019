(defproject gen-dsed "1.0.0"
  :description "parses an input file and writes djvused input files"
  :url "http://github.com/rwtodd/small_programs_2019"
  :license {:name "MIT"
            :url "MIT"}
  :dependencies [[org.clojure/clojure "1.10.1"]]
  :main ^:skip-aot gen-dsed.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})

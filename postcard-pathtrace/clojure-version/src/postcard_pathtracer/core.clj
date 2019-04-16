(ns postcard-pathtracer.core
  (:gen-class))

(defrecord v3 [^float x ^float y ^float z])

(defn make-v3
  ^v3 [^double v] (->v3 v v v))

(defn v3-+ ^v3 [^v3 a ^v3 b]
  (->v3 (+ (.x a) (.x b))
        (+ (.y a) (.y b))
        (+ (.z a) (.z b))))

(defn v3-scale ^v3 [^v3 a ^double b]
  (->v3 (* (.x a) b)
        (* (.y a) b)
        (* (.z a) b)))
  
(defn v3-* ^v3 [^v3 a ^v3 b]
  (->v3 (* (.x a) (.x b))
        (* (.y a) (.y b))
        (* (.z a) (.z b))))

(defn v3-dot ^double [^v3 a ^v3 b]
  (+ (+ (* (.x a) (.x b))
        (* (.y a) (.y b)))
     (* (.z a) (.z b))))

(defn v3-not ^v3 [^v3 a]
  (v3-scale a (/ 1.0 (Math/sqrt (v3-dot a a)))))

(defn box-test ^double [^v3 pos ^v3 ll ^v3 ur]
  (let [ll (v3-+ pos (v3-scale ll -1))
        ur (v3-+ ur (v3-scale pos -1))]
    (* -1.0
       (min (.x ll) (.x ur) (.y ll) (.y ur) (.z ll) (.z ur)))))

(defonce letters "5O5_5W9W5_9_AOEOCOC_A_E_IOQ_I_QOUOY_Y_]OWW[WaOa_aWeWa_e_cWiO")
(defonce letterz
  [
   [\5\O\5\_] [\5\W\9\W] [\5\_\9\_] [\A\O\E\O]
   [\C\O\C\_] [\A\_\E\_] [\I\O\Q\_] [\I\_\Q\O]
   [\U\O\Y\_] [\Y\_\]\O] [\W\W\[\W] [\a\O\a\_]
   [\a\W\e\W] [\a\_\e\_] [\c\W\i\O] ])

(defonce curves  [ (->v3 -11 6 0) (->v3 11 6 0) ])

(def query-begin-e
  (into [] (map (fn [ls]
                  (let [begin  (v3-scale (->v3 (- (int (nth ls 0)) 79)
                                               (- (int (nth ls 1)) 79)
                                               0)
                                         0.5)
                        e  (v3-+ (v3-scale begin -1)
                                 (v3-scale (->v3 (- (int (nth ls 2)) 79)
                                                 (- (int (nth ls 3)) 79)
                                                 0)
                                           0.5))]
                    [begin e])))
        (partition-all 4 letters)))

(def v3--30--0p5--30 (->v3 -30, -0.5, -30))
(def v3-30-18-30 (->v3 30, 18, 30))
(def v3--25-17--25 (->v3 -25, 17, -25))
(def v3-25-20-25 (->v3 25, 20, 25))
(def v3-1p5-18p5--25 (->v3 1.5, 18.5, -25))
(def v3-6p5-20-25 (->v3 6.5, 20,   25))

(defn query-db
  [^v3 pos]
  (let [f     (->v3 (.x pos) (.y pos) 0.0)
        ldist (Math/sqrt
               (reduce min
                      (map (fn [[begin e]]
                             (let [o (v3-+ f
                                           (v3-scale
                                            (v3-+ begin
                                                  (v3-scale e
                                                            (min (* -1 (min (/ (v3-dot (v3-+ begin (v3-scale f -1)) e)
                                                                               (v3-dot e e))
                                                                            0))
                                                                 1)))
                                            -1))]
                               (v3-dot o o)))
                          query-begin-e)))
        cdist (reduce min (map (fn [curve]
                                (let [o (v3-+ (v3-scale curve -1) f)]
                                  (if (> (.x o) 0)
                                    (Math/abs (- (Math/sqrt (v3-dot o o))
                                                 2))
                                    (let [oy
                                          (->v3 (.x o) (+ (.y o) (if (pos? (.y o)) -2 2)) (.z o))]
                ;;                          (update o :y #(+ % (if (pos? %) -2 2)))]
                                      (Math/sqrt (v3-dot oy oy))))))
                              curves))
        dist (- (Math/pow (+ (Math/pow (min ldist cdist) 8)
                             (Math/pow (.z pos) 8))
                          0.125)
                0.5)
        
        ; default  hitType = HIT_LETTER; 
        roomDist (min (- (min (box-test pos
                                        v3--30--0p5--30
                                        v3-30-18-30)
                              (box-test pos
                                        v3--25-17--25
                                        v3-25-20-25)))
                      (box-test (->v3 (mod (Math/abs (.x pos)) 8.0) (.y pos) (.z pos))
                                v3-1p5-18p5--25            
                                v3-6p5-20-25))
        sunDist (- 19.9 (.y pos))]
    ;; DEBUG (println (format "%f %f %f" dist roomDist sunDist))
    (if (< roomDist (min sunDist dist))
      [roomDist :hit-wall]
      (if (< sunDist (min roomDist dist))
        [sunDist :hit-sun]
        [dist :hit-letter]))))

(defn marching [^v3 origin ^v3 direction]
  (loop [total-d 0.0
         no-hit-count 0]
    (if (>= total-d 100.0)
      [:hit-none nil nil]
      (let [hit-pos      (v3-+ origin (v3-scale direction total-d))
            [d hit-type] (query-db hit-pos)]
        (if (or (< d 0.01) (= no-hit-count 99))
          [hit-type
           hit-pos
           (v3-not (->v3 (- (first (query-db (v3-+ hit-pos (->v3 0.01, 0, 0)))) d)
                         (- (first (query-db (v3-+ hit-pos (->v3 0, 0.01, 0)))) d)
                         (- (first (query-db (v3-+ hit-pos (->v3 0, 0, 0.01)))) d)))]
          (recur (+ total-d d) (inc no-hit-count)))))))

(defn trace
  [^v3 origin ^v3 direction]
  (let [light-direction (v3-not (->v3 0.6 0.6 1))]
    (loop [bounce-count 3
           origin       origin
           direction    direction
           color        (->v3 0 0 0)
           attenuation  1.0]
      (if (zero? bounce-count)
        color
        (let [[hit-type ^v3 sample-pos ^v3 normal] (marching origin direction)]
          (case hit-type
            :hit-none
            color
            
            :hit-sun
            (v3-+ color (v3-scale (->v3 50 80 100) attenuation))
            
            :hit-letter
            (let [new-dir (v3-+ direction (v3-scale normal (v3-dot normal
                                                                   (v3-scale direction -2))))
                  new-orig (v3-+ sample-pos (v3-scale new-dir 0.1))]
              (recur (dec bounce-count)
                     new-orig
                     new-dir
                     color
                     (* attenuation 0.2)))
            
            
            :hit-wall
            (let [incidence  (v3-dot normal light-direction)
                  p          (* 6.283185 (rand))
                  c          (rand)
                  s          (Math/sqrt (- 1.0 c))
                  g          (if (< (.z normal) 0) -1 1)
                  u          (/ -1.0 (+ g (.z normal)))
                  v          (* u (.x normal) (.y normal))
                  new-dir    (v3-+
                              (v3-+
                               (v3-scale (->v3 v
                                               (+ g (* (.y normal) (.y normal) u))
                                               (- (.y normal)))
                                         (* s (Math/cos p)))
                               (v3-scale (->v3 (inc (* g (.x normal) (.x normal) u))
                                               (* g v)
                                               (* (- g) (.x normal)))
                                         (* (Math/sin p) s)))
                              (v3-scale normal (Math/sqrt c)))
                  new-orig   (v3-+ sample-pos (v3-scale new-dir 0.1))
                  new-atten  (* attenuation 0.2)
                  new-color  (if (and (> incidence 0)
                                      (= :hit-sun
                                         (first (marching (v3-+ sample-pos (v3-scale normal 0.1))
                                                          light-direction))))
                               (v3-+ color (v3-scale (->v3 500 400 100)
                                                     (* new-atten incidence)))
                               color)]
              (recur (dec bounce-count)
                     new-orig
                     new-dir
                     new-color
                     new-atten))))))))
  

(defn reinhard ^v3
  [^long samples ^v3 color]
  (let [c1 (v3-+ (v3-scale color
                           (/ 1.0 samples))
                 (make-v3 (/ 14.0 241.0)))
        o  (v3-+ c1 (make-v3 1))]
    (->v3 (* (/ (.x c1) (.x o)) 255)
          (* (/ (.y c1) (.y o)) 255)
          (* (/ (.z c1) (.z o)) 255))))

(def v3-zero (make-v3 0.0))
(defn pic
  [^long w ^long h ^long samples]
  (let [^v3 pos (->v3 -22 5 25)
        ^v3 goal (v3-not (v3-+ (->v3 -3 4 0) (v3-scale pos -1.0)))
        ^v3 left (v3-scale (v3-not (->v3 (.z goal) 0.0 (- (.x goal))))
                           (/ 1.0 w))
        ^v3 up   (->v3
                  (- (* (.y goal) (.z left)) (* (.z goal) (.y left)))
                  (- (* (.z goal) (.x left)) (* (.x goal) (.z left)))
                  (- (* (.x goal) (.y left)) (* (.y goal) (.x left))))]
    (println (format "P3 %d %d 255" w h))
    (loop [y h, x w]
      (if (zero? y)
        nil
        (let [^v3 color (reinhard
                         samples
                         (loop [total v3-zero, n samples]
                           (if (zero? n)
                             total
                             (recur
                              (v3-+ total
                                    (trace pos
                                           (v3-not (v3-+
                                                    (v3-+ goal
                                                          (v3-scale left
                                                                    (+ (- x (/ w 2.0))
                                                                       (rand))))
                                                    (v3-scale up
                                                              (+ (- y (/ h 2.0))
                                                                 (rand)))))))
                              (dec n)))))]
          (println (format "%d %d %d"
                           (int (.x color))
                           (int (.y color))
                           (int (.z color))))
          (let [zx? (zero? x)]
            (recur (if zx? (dec y) y)
                   (if zx? w       (dec x)))))))))
  
(defn pic->file
  [fn x y samps]
  (with-open [wtr (clojure.java.io/writer fn)]
    (binding [*out* wtr]
      (pic x y samps))))

; example (pic 960 540 8)

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))

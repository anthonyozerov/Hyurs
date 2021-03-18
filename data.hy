(require [hy.contrib.walk [let]])
(import
  json pytz
  [utils [*]]
  [dateutil.parser [parse :as dateparse]])

(setv events-path  "data/imported.json")
(setv mapping-path "data/mapping.json")
(setv state-path   "data/state.json")

(defn events   [] (load-json events-path))
(defn mappings [] (load-json mapping-path))
(defn state    [] (load-json state-path))

(defn mapping [mapping-name]
  (get-or (load-json mapping-path) mapping-name {}))

(defn last-update-time []
  (get-or (load-json state-path) "time_updated" "UNKNOWN"))

(defn dateparse-tz [date-str]
  (setv t (dateparse date-str))
  (if (= None (. t tzinfo))
    (pytz.utc.localize t)
    t))

(defn file-write
  [fpath contents]
  (with [f (open fpath "w+")]
    (.write f contents)))

(defn file-read
  [fpath]
  (with [f (open fpath "r")]
    (.read f)))

(defn file-read-lines
  [fpath]
  (with [f (open fpath "r")]
    (map (fn [s] (if (= (last s) "\n")
                   (cut s 0 (- (len s) 1))
                   s))
         (.readlines f))))

(defn save-json
  [fpath objects]
  (->> objects
       (.dumps json)
       (file-write fpath)))

(defn load-json
  [fpath]
  (->> fpath
       file-read
       (.loads json)))

(defn tag-parse
  [s]
  (.split s ":"))

(defn tag-write
  [htag]
  (.join ":" htag))

(defn transform
  [json-path &rest funcs]
  (save-json json-path
             ((fn-thread #*funcs)
              (load-json json-path))))

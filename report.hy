(require [hy.contrib.walk [let]])
(import
  [stats [*]]
  datetime)

(setv per-level-indent "    ")
(setv significant-digits 1)
(setv report-filename-prefix "out/report-")

(defn tree->lines
  [tree]
  (if (leaf? tree)
    "EMPTY"
    (cons (str-join (node-key tree)
                    ": "
                    (round (tree-sum tree)
                           significant-digits))
          (mapl (fn [l]
                  (str-join per-level-indent
                            l))
                (tl->lines (node-subs tree))))))

(defn tl->lines
  [tl]
  (+l #*(mapl tree->lines
              (sort tl
                    (fn [tree]
                      (- (tree-sum tree)))))))

(defn write-report
  [mapping-name t1-str t2-str]
  (.join "\n"
         (tl->lines (times->treelist mapping-name
                                     t1-str
                                     t2-str))))

(defn report-with-header
  [report-text t1-str t2-str]
  (let [now (cut (str (datetime.datetime.now)) 0 19)] ; cut out time of day
    (data.file-write (str-join report-filename-prefix
                               now
                               ".txt")
                     (+ "HYURS REPORT\n"
                        "Generated: "  now "\n"
                        "Start time: " t1-str "\n"
                        "End time: "  t2-str "\n"
                        "Based on data last updated at: "
                        (data.last-update-time) "\n\n"
                        report-text))))
(defn save-report
  [mapping-name t1-str t2-str]
  (report-with-header (write-report mapping-name
                                    t1-str
                                    t2-str)
                      t1-str
                      t2-str))

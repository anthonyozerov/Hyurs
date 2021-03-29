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

(defn write-multi-report
  [mapping-name t1-strs t2-strs]
  (if (empty? t1-strs)
    ""
    (str-join "\n\n"
              "TIME PERIOD: " (cut (first t1-strs) 0 10)
              " to " (cut (first t2-strs) 0 10)
              "\n"
              (write-report mapping-name
                            (first t1-strs)
                            (first t2-strs))
              (write-multi-report mapping-name
                                  (rst t1-strs)
                                  (rst t2-strs)))))

(defn report-with-header
  [report-text t1-str t2-str &optional [filename ""]]
  (let [now (cut (str (datetime.datetime.now)) 0 19)] ; cut out time of day
    (data.file-write (if (= 0 (len filename))
                       (str-join report-filename-prefix
                                 now
                                 ".txt")
                       (if (!= (cut filename -4)
                               ".txt")
                         (str-join filename ".txt")
                         filename))
                     (+ "HYURS REPORT\n"
                        "Generated: "  now "\n"
                        "Start time: " t1-str "\n"
                        "End time: "  t2-str "\n"
                        "Based on data last updated at: "
                        (data.last-update-time) "\n\n"
                        report-text))))
(defn save-report
  [mapping-name t1-str t2-str &optional [filename ""]]
  (report-with-header (write-report mapping-name
                                    t1-str
                                    t2-str)
                      t1-str
                      t2-str
                      filename))

(defn save-multi-report
  [mapping-name t1-strs t2-strs &optional [filename ""]]
  (report-with-header (write-multi-report mapping-name
                                          t1-strs
                                          t2-strs)
                      (first t1-strs)
                      (last t2-strs)
                      filename))

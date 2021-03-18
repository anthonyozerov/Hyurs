(import
  data
  [utils [*]])

(defn build-dict
  [unknown-names]
  (dfor name unknown-names
        [name
         (input (.join " "
                       ["Enter tag hierarchy for event with name:"
                        name
                        "\n"]))]))
(defn event-names []
  (map (fn [event]
         (get event "fullname"))
       (data.events)))

(defn known-event-names [mname]
  (.keys (data.mapping mname)))

(defn ask []
  (setv mapping-name (input "Enter name of tag hierarchy: "))
  (print "----")
  (print "Enter tag hierarchies for event names as you are prompted.")
  (print "The separator is the symbol ':'.")
  (print "(For example, you might type: work:academics:computation theory")
  (print "----")
  (setv d (build-dict (- (event-names)
                         (known-event-names mapping-name))))
  (data.transform data.mapping-path
                  (fn [mappings]
                    (merge-if-exists mappings
                                     mapping-name
                                     d))))

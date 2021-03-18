(require [hy.contrib.walk [let]])
(import
  data
  [utils [*]]
  [dateutil.parser [parse :as dateparse]])

(defn make-node [key val subnodes] (, key val subnodes))
(defn node-key [node] (get node 0))
(defn node-val [node] (get node 1))
(defn node-subs [node] (get node 2))
(defn leaf? [tree] (= tree 'Leaf))

(defn tl-insert [trees h-key val]
  """Inserts into a list of nodes as defined by make-node.
     h-key is a hierarchical key; the ith element defines
     the key of the node on the ith level, and the value is
     linked with the last key on the final level.
     tree-insert is a helper for this function."""
  (if (empty? trees)
    [(tree-insert 'Leaf h-key val)] ; add new node
    (let [tree (first trees)]
      (if (= (node-key tree)
             (first h-key))
        (cons (tree-insert tree h-key val)
              (rst trees)) ; found where to add
        (cons tree
              (tl-insert (rst trees) h-key val))))))

(defn tree-insert
  [tree h-key val]
    """Tree is a node as defined by make-node. It is assumed that if
       you're adding into tree, the node-key of tree is h-key."""
  (if (leaf? tree)
    (if (singleton? h-key)
      (make-node (first h-key) val [])
      (let [new-node (make-node (first h-key) 0 [])]
        (tree-insert new-node h-key val)))
    (cond
      [(and (singleton? h-key)
            (= (first h-key)
               (node-key tree)))
       (make-node (node-key tree)
                  (+ val
                     (node-val tree))
                  (node-subs tree))]
      [(= (first h-key) (node-key tree))
       (make-node (node-key tree)
                  (node-val tree)
                  (tl-insert (node-subs tree)
                             (rst h-key)
                             val))]
      [True (error "Tree does not match hierarchical key: " h-key)])))

(defn tl-multi-insert
  [trees h-keys vals]
  (if (empty? h-keys)
    trees
    (tl-multi-insert (tl-insert trees
                                (first h-keys)
                                (first vals))
                     (rst h-keys)
                     (rst vals))))

(defn tl-getter
  [getter-func trees hkey]
  (if (empty? trees)
    None
    (let [tree (first trees)]
      (if (= (node-key tree)
             (first hkey))
        (if (singleton? hkey)
          (getter-func tree) ; found!
          (tl-getter getter-func
                     (node-subs tree)
                     (rst hkey)))
        (tl-getter getter-func
                   (rst trees)
                   hkey)))))

(defn tl-get [trees hkey]
  """Gets the value associated with the tree node with hierarchical key
     hkey; else None."""
  (tl-getter node-val trees hkey))

(defn tl-subget [trees hkey]
  """Gets the subtree rooted at the tree node with hierarchical key
     hkey; else None."""
  (tl-getter identity trees hkey))

(defn tree-sum
  [tree]
    """Gets the sum of all values in tree"""
  (cond
    [(= None tree) 0]
    [(empty? (node-subs tree))
     (node-val tree)]
    [True (+ (node-val tree)
             #*(map tree-sum
                    (node-subs tree)))]))

(defn events-between [t1-str t2-str]
  (setv t1 (data.dateparse-tz t1-str))
  (setv t2 (data.dateparse-tz t2-str))
  (filter (fn [evt]
            (let [t (data.dateparse (get evt "start"))]
            (if (and (<= t1 t) (<= t t2))
              True
              False)))
          (data.events)))

(defn mapped-events
  [mapping-name events]
  (setv htag-map (data.mapping mapping-name))
  (mapl (fn [event]
          (setv ts (data.dateparse (get event "start")))
          (setv te (data.dateparse (get event "end")))
          {:start    ts
           :end      te
           :htag     (data.tag-parse (get htag-map (get event "fullname")))
           :duration (/ (. (- te ts) seconds) 3600)})
        events))

(defn select-events
  [mapping-name &optional [t1-str "2020-01-01"] [t2-str "2025-01-01"]]
  (mapped-events mapping-name
                 (events-between t1-str t2-str)))

(defn events->treelist
  [events]
  "Takes a list of events, as produced by select-events, and builds up a tree"
  (tl-multi-insert [] ; below, can't map directly because interpreted as keyword arg
                   (mapl (fn [event] (:htag event)) events)
                   (mapl (fn [event] (:duration event)) events)))

(defn times->treelist
  [mapping-name t1-str t2-str]
  (events->treelist (select-events mapping-name t1-str t2-str)))

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

(defn tree-max-depth
  [tree]
  (inc (tl-max-depth (node-subs tree))))

(defn tl-max-depth
  [tl]
  (if (empty? tl)
    0
    (reduce max
            (map tree-max-depth
                 tl))))

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

(defn sum-tree
  [tree]
  """Helper function for sum-treelist below."""
  (make-node (node-key tree)
             (tree-sum tree)
             (sum-treelist (node-subs tree))))

(defn sum-treelist
  [tl]
  """Converts a treelist where every tree node stores the value assigned
     uniquely to it, to a treelist where every tree node stores its
     tree-sum."""
  (mapl sum-tree tl))

(defn sumtree-fill-uncategorised
  [tree]
  """Helper function for treelist-fill-uncategorised below."""
  (let [subtree-sum (sum (map node-val (node-subs tree)))]
    (make-node (node-key tree)
               (node-val tree)
               (let [tl (node-subs tree)]
                 (if (or (= (node-val tree)
                            subtree-sum)
                         (= (len (node-subs tree))
                            0))
                   (sum-tl-fill-uncategorised tl)
                   (cons (make-node 'Uncategorised
                                    (- (node-val tree)
                                       subtree-sum)
                                    [])
                         (sum-tl-fill-uncategorised tl)))))))

(defn sum-tl-fill-uncategorised
  [tl]
  """The values of the subnodes of a tree don't necessarily sum up to the
     value of the node. This function takes a sum tree list and creates nodes
     with the special key Uncategorised to correct this
     (useful for graphing functions)
  """
  (mapl sumtree-fill-uncategorised tl))

(defn tree-extender
  [tree n]
  (if (= n 1)
    tree
    (make-node (node-key tree)
               (node-val tree)
               (treelist-extender
                (if (empty? (node-subs tree))
                  [(make-node 'Uncategorised
                              (node-val tree)
                              [])]
                  (node-subs tree))
                (dec n)))))

(defn treelist-extender
  [treelist n]
  """Extends a treelist to have depth n, creating nodes with the
     Uncategorised symbol and the value of their parent as necessary,
     and chopping off any parts beyond depth n."""
  (mapl (fn [tree] (tree-extender tree n))
        treelist))

(defn blown-up-treelist
  [tl &optional [key-transform identity] [val-transform identity]]
  (defn blower-upper
    [tl key-start]
    (reduce +
            (map (fn [tree]
                   (let [full-key (snoc key-start (node-key tree))]
                     (cons (, ; make a tuple
                            (key-transform full-key)
                            (val-transform (node-val tree)))
                           (blower-upper (node-subs tree)
                                              full-key))))
                   tl)
            []))
  (blower-upper tl []))

(defn tree-rank
  [sum-tl key]
  """Returns the rank of the value of key as compared to the values of
     the other children of key's parent node. The parent node is searched
     for in sum-tl."""
  (if (empty? key) (error "Cannot find tree-rank of an empty key"))
  (let [sibling-nodes (if (not (singleton? key))
                        (node-subs (tl-subget sum-tl
                                              (butlastl key)))
                        sum-tl)
        val (tl-get sum-tl key)]
    (reduce (fn [bigger-count next-tree]
              (+ bigger-count
                 (if (> (node-val next-tree)
                        val)
                   1
                   0)))
            sibling-nodes
            0)))

(defn tree-ranks
  [sum-tl key]
  """Returns a list of ranks, where the 0th rank is the rank of the key's
     root tree in the sum tree list sum-tl, and the ith rank is the rank
     of the ith part of the key out of the subnodes of the tree rooted at
     the (i-1)th part of the key."""
  (mapl (fn [key-prefix]
         (tree-rank sum-tl key-prefix))
       (prefixes key)))

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
                   (mapl (fn [event] (:htag event))
                         events)
                   (mapl (fn [event] (:duration event))
                         events)))

(defn times->treelist
  [mapping-name t1-str t2-str]
  (events->treelist (select-events mapping-name t1-str t2-str)))

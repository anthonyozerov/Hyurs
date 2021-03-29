(require [hy.contrib.walk [let]])

(defn cons [el l] (+ [el] l))
(defn snoc [l el] (+ l [el]))


(defn rst [l] (list (rest l)))
(defn singleton? [l] (empty? (rst l)))
(defn butlastl [l] (cut l 0 (- (len l) 1)))
(defn mapl [f l] (list (map f l)))
(defn filterl [f l] (list (filter f l)))

(defn partitionl
  [f l]
  (,
   (filterl (fn [x] (not (f x)))
            l)
   (filterl f
            l)))

(defn list->str
  [charlist]
  (.join "" charlist))

(defn fn-thread
  [&rest funcs]
    """Takes a list of single-argument functions and composes/'threads' them
       together into a single function that passes its result as the argument
       to the next function in funcs."""
  (if (empty? funcs) (error "fn-thread passed empty function list"))
  (if (singleton? funcs)
    (first funcs)
    (fn [x]
      ((fn-thread #*(rst funcs))
       ((first funcs) x)))))

(defn get-or
  [dict key default]
  (if (in key (.keys dict))
    (get dict key)
    default))

(defn merge-if-exists
  [dict key to-merge-with]
  """Updates dict[key] to be the merge of the current value and to-merge-with
     if it currently has a value, or just to-merge-with if there is no value."""
  (assoc dict key
         (| (get-or dict key {})
            to-merge-with))
  dict)

(defn str-join
  [&rest args]
  (+ #*(map str args)))

(defn +l
  [&rest args]
  """Use to concatenate lists in a way that handles the empty case
     (since (+) returns 0) and the singleton case, which otherwise
     throws an error."""
  (cond
    [(empty? args) []]
    [(singleton? args) (first args)]
    [True (+ #*args)]))

(defn sort
  [l &optional [f identity]]
  (sorted l :key f))

(defmacro setr
  [var val]
  `(do
     (setv ~var ~val)
     ~var))

(defn get-ith
  [i]
  (fn [l] (get l i)))

(defn prefixes
  [l]
  (if (singleton? l)
    [l]
    (snoc (prefixes (butlastl l))
          l)))

(defn slice-by-len
  [lol &optional [f identity]] ; list of lists
  (defn slicer
    [remaining-lol i acc]
    (if (empty? remaining-lol)
      acc
      (let [[not-next-len next-len]
            (partitionl (fn [l]
                          (= (len (f l)) i))
                        remaining-lol)]
      (slicer not-next-len
              (+ i 1)
              (snoc acc
                    next-len)))))
  (slicer lol 0 []))

(defn not-fn
  [f]
  (fn [&rest args]
    (not (f #*args))))

(defn sign
  [x]
  (if (< x 0)
    -1
    1))

(defn error
  [&rest args]
  """Raises an exception that has the contents of args, space-separated,
     as the message."""
  (->> args
       (map str)
       (list)
       (.join " ")
       (Exception)
       (raise)))

(defn dbprint
  [val &optional [comment "- debug print"]]
  (print val comment)
  val)

(defn hex->col
  [hexstr]
  ((fn [l] (mapl (fn [lst]
                  (int (list->str lst)
                       16))
                (zip (take-nth 2 l)
                     (take-nth 2 (rst l)))))
   (rst hexstr)))

(defn col->hex
  [col-list]
  (+ "#"
     (list->str (mapl (fn [d]
                        (let [hx (cut (hex d) 2)]
                          (if (= (len hx) 2)
                            hx
                            (+ "0" hx))))
                      col-list))))

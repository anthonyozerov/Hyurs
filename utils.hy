(defn rst [l] (list (rest l)))

(defn singleton? [l] (empty? (rst l)))

(defn cons [el l] (+ [el] l))

(defn mapl [f l] (list (map f l)))

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

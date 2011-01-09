; sehm: s-expression html markup
;
; An html engine featuring:
;
; * composable elements
; * custom tags
; * layout templates
; * html rendering decoupled from tag structure
; * renderer does pretty printing by default
;
; See the accompanying readme for more
;


(load "lib/util.arc")
(wipe tag tab row) ; vanilla html.arc defines these as macros -- they gets in the way

(def parse-attrs-nodes (xs)
     "Parse xs into two lists: an alist of attributes, 
     and the remainder of xs as child nodes"
     (with (attrs (queue) children (list))
         (while xs
                (if (asym car.xs)
                    (enq (list pop.xs pop.xs) attrs)
                    (do (= children xs) (wipe xs))))
         (obj attrs (qlist attrs) children (flat children)))) ; we flatten children because they could contain nils, and it won't flatten the tree structure because it's not determined by lisp lists

(def build-tag (name attrs children)
     (annotate 'tag (obj name name attrs attrs children children)))

(def atag (x) (is (type x) 'tag))

(def tag (name args)
     (let res (parse-attrs-nodes args)
       (build-tag name res!attrs res!children)))

(def element (name . args)
     (tag name args))

; convenience
(= e element)

(def alpop (x attr)
     "pop an element from an alist"
     (do1 (alref x attr)
          (pull [is (car _) attr] x)))

(mac alput (x args)
  (w/uniq (p k v)
     `(each p (pair ,args) 
        (let (k v) p
           (when (asym k) 
             (if (alref ,x k) (alpop ,x k))
             (= ,x (push p ,x)))))))

(mac deftag (name . body)
     "deftag allows you to define a custom tag (in reality it's just a function)
     Whatever arguments passed to this function get parsed into attributes and children
     The following variables are automagically defined
     'attrs: attributes extracted from arguments (an alist)
     'children: child nodes, extracted from arguments
     'attr: a function to get an attirubte from 'attrs
     'popattr: like 'attr but removes the attribute from 'attrs
     'addattr: adds a new attribute to 'attrs (persumably, before passing them to another function)"
    `(def ,name args 
       (let res (parse-attrs-nodes args)
        (with (attrs res!attrs children res!children)
          (with (popattr [alpop attrs _] 
                 attr [alref attrs _] 
                 addattr (fn args (alput attrs args)))
              ,@body)))))

(def deftagalias (alias name)
     (= alias (sym alias))
     (eval `(deftag ,alias (build-tag ,name attrs children))))

(mac deftagc (name . body)
     "A custom tag that only runs where there is content"
     `(deftag ,name
        (if children (do ,@body))))

; define basic tags as functions like this:
; (def div args (tag "div" args))
(each tagname (list "div" "span" "html" "title" "head" "body" "p" "h1" "h2" "h3" "tr" "td")
      (deftagalias tagname tagname))

(each (alias name) (pair (list "section" "div" "par" "p"))
      (deftagalias alias name))

(def indent-space (level)
     (string:n-of (* 2 level) " "))

; global .. ideally should be a thread local
(= current-indent-level* 0)
(def indent () (++ current-indent-level*))
(def outdent () (-- current-indent-level*))
(def pr-indent () (pr (indent-space current-indent-level*)))
(def prn-indent () (prn) (pr-indent))

(def pr-attrs (attrs)
     ; assumes attrs is an alist
     (each (k v) attrs
         (if (and k v)
           (pr " " k "=\"" v "\""))))

(def pr-tag-open (name attrs)
     (pr "<" name)
     (pr-attrs attrs)
     (pr ">"))

(def pr-tag-selfclose (name attrs)
     (pr "<" name)
     (pr-attrs attrs)
     (pr " />"))

(def pr-tag-close (name)
     (pr "</" name ">"))

(def pr-tag-inline (name attrs children)
     (pr-tag-open name attrs)
     (pr-node children)
     (pr-tag-close name))

(def pr-node (node)
     (if (no node) nil
         (atag node) (pr-tag node)
         (acons node) 
             (each n (intersperse " " node)
                   (pr-node n))
         t (pr node)))

(def pr-tag-normal (name attrs children)
       (pr-tag-open name attrs)
       (when children
         (each it children
             (indent)
             (prn-indent)
             (pr-node it)
             (outdent))
         (prn-indent))
       (pr-tag-close name))

(def pr-tag (tag)
     (let e (rep tag)
       (let n (string e!name)
         (if (in n "link" "img" "input") (pr-tag-selfclose e!name e!attrs)
             (in n "a" "u" "i" "em" "b" "p" "title") (pr-tag-inline e!name e!attrs e!children)
             t (pr-tag-normal e!name e!attrs e!children)))))


(def render-html args
     "Use this to render your tag structure into html"
     ; (prn "<!doctype html>") ; not exactly ..
     (pr-node args)
     (prn))

(deftag items
      (e "ul" 'class attr!class
        (map [e "il" 'class attr!itemclass _] children)))

(deftag jscript
        "takes a list of js files and creates tags to include them"
        (map [e "script" 'type "text/javascript" 'src _] children))

(deftag csslink
        "takes a list of css files and creates tags to include them"
        (map [e "link" 'rel "stylesheet" 'type "text/css" 'href _] children))

(def link (href text)
     (e 'a 'href href text))

(deftag page
    (html
      (head (title attr!title)
            (jscript attr!js)
            (csslink attr!css)
            (inlinecss attr!inlinecss)
            (inlinejs attr!inlinejs))
      (body children)))

(deftag tab
        (addattr 'cellpadding 0 'cellspacing 0)
        (build-tag 'table attrs children))

(deftag row
    (tab (tr (map td children))))

(deftag col
    (map div children))

(deftagc inlinecss 
        (e 'style 'type "text/css" children))

(deftagc inlinejs
        (e 'script 'type "text/javascript" children))

(def k (kls . args)
     (div 'class kls args))


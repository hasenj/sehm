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
(wipe tag) ; vanilla html.arc defines this as a macro -- it gets in the way

(def parse-attrs-nodes (xs)
     "Parse xs into two lists: an alist of attributes, 
     and the remainder of xs as child nodes"
     (with (attrs (queue) children (list))
         (while xs
                (if (asym car.xs)
                    (enq (list pop.xs pop.xs) attrs)
                    (do (= children xs) (wipe xs))))
         (obj attrs (qlist attrs) children children)))

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

; define basic tags as functions like this:
; (def div args (tag "div" args))
(each tagname (list "div" "span" "html" "title" "head" "body" "p" "h1" "h2" "h3")
  (let tagsym (sym tagname)
    (eval `(def ,tagsym args (tag ,tagname args)))))

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
     (each attr attrs
        (with (key (string (attr 0)) 
               val (string "\"" (attr 1) "\""))
           (if (and key val) (pr " " key "=" val)))))

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
             (each n (intersperse " " flat.node) ; flat to remove nils
                   (pr-node n))
         t (pr node)))

(def pr-tag-normal (name attrs children)
       (pr-tag-open name attrs)
       (when children
         (each it (flat children)
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
     (prn "<!doctype html>")
     (pr-node args)
     (prn))

(mac deftag (name . body)
     "deftag allows you to define a custom tag (in reality it's just a function)
     Whatever arguments passed to this function get parsed into attributes and children
     The following variables are automagically defined
     'attrs: attributes extracted from arguments (an alist)
     'children: child nodes, extracted from arguments
     'attr: a function to get an attirubte from 'attrs
     'popattr: like 'attr but removes the attribute from 'attrs"
    `(def ,name args 
       (let res (parse-attrs-nodes args)
        (with (attrs res!attrs children res!children)
          (with (popattr [alpop attrs _] attr [alref attrs _])
              ,@body)))))

(deftag items
      (e "ul" 'class attr!class
        (map [e "il" 'class attr!itemclass _] children)))

(def jscript args
        "takes a list of js files and creates tags to include them"
        (map [e "script" 'type "text/javascript" 'src _] (flat args)))

(def csslink args
        "takes a list of css files and creates tags to include them"
        (map [e "link" 'rel "stylesheet" 'type "text/css" 'href _] (flat args)))

(deftag page
    (html
      (head (title attr!title)
            (jscript attr!js)
            (csslink attr!css))
      (body children)))

(deftag blogpage
        (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))


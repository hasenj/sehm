; sehm: s-expression html markup
;
; html tree nodes have attributes attached to them, to simulate that:
;
; (node-name 'attr value 'attr value child-node child-node child-node)
;
; For example:
;
;   (div 'id "main" (span "text"))
; 
; A child node could be plain text or another html node
; attribute values are mostly strings
;
; Attributed are designated by symbols, the rest is child nodes


(load "lib/util.arc")

(def parse-attrs-nodes (xs)
     "Parse xs into two lists: an alist of attributes, 
     and the remainder of xs as child nodes"
     (with (attrs (queue) children (list))
         (while xs
            (if (asym (car xs))
                (with (a (pop xs) b (pop xs))
                   (if b (enq (list a b) attrs)))
                (= children (drain (pop xs)))))
         (obj attrs (qlist attrs) children children)))

(def build-tag (name attrs children)
     (annotate 'tag (obj name name attrs attrs children children)))

(def atag (x) (is (type x) 'tag))

(def indent-space (level)
     (string:n-of (* 2 level) " "))

(def pr-attrs (attrs)
     ; assumes attrs is an alist
     (each attr attrs
        (with 
          (key (string (attr 0))
           val (string "\"" (attr 1) "\""))
           (pr " " key "=" val ""))))

(def prn-tag-object (ttag (o indent-level 0))
     (let e (rep ttag)
       (pr (indent-space indent-level) "<" e!name)
       (pr-attrs e!attrs)
       (if (and (no e!children) e!selfclose) (pr "/>") (pr ">"))
       (aif e!children 
           (do (prn) 
             (prn-nodes-helper it (+ 1 indent-level))
             (pr (indent-space indent-level))))
       (prn "</" e!name ">")))

(def prn-nodes-helper (x (o indent-level 0))
     (if (no x)         nil
         (atag x)      (prn-tag-object x indent-level)
         (acons x)     (each child x (prn-nodes-helper child indent-level))
         (prn (indent-space indent-level) x)))

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

(def render-html args
     "Use this to render your tag structure into html"
     (prn-nodes-helper args))

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

(render-html
 (html
  (head (title "Hello world"))
  (body 
    (div 'id "content"
      (h1 "Main section")
      (p "First paragraph")))))

(deftag items
      (e "ul" 'class attr!class
        (map [e "il" 'class attr!itemclass _] children)))

(render-html (items 'class "list" 'itemclass "item" 
                       "item1" "item2"))
(render-html (items "item1" "item2"))

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

(render-html (page 'title "Sample" "yes"))
(render-html (page 'title "Html template" 'js '("first.js" "second.js") (div "This is my content")))

(deftag blogpage
        (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))

(render-html (blogpage "This is my post"))
(render-html (page 'title "Sample" 'js nil "yes"))


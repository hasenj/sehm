; This is not a haml clone

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
; Attributed are designated by symbols, the rest is child noes


(load "lib/util.arc")

(= is-attr asym)

(def attrs-and-children (xs)
     "Parse xs into two lists: an alist of attributes, 
     and the remainder of the list of child nodes"
       (with (attrs (queue) children (list))
         (while xs
           (with (a (car xs) b (cadr xs))
             (if (and (asym a) b)
                 (do (enq (list a b) attrs) (pop xs) (pop xs))
                 (= children (drain (pop xs))))))
         (obj attrs (qlist attrs) children children)))

(prn (attrs-and-children '(id "home" class "user")))
(prn (attrs-and-children '(id "home" class "user" "content" "content" "content")))

(def build-tag (name attrs children)
     (annotate 'tag (obj name name attrs attrs children children)))

(= template (build-tag "div" (tablist:obj id "main") "content"))

(prn "The tag name: " ((rep template) 'name))
(prn "The tag attrs: " ((rep template) 'attrs))
(prn "The tag childs: " ((rep template) 'children))

(def atag (x) (is (type x) 'tag))

(def indent-space (level)
     (string:n-of (* 2 level) " "))

(def prn-nodes-helper (x (o indent-level 0))
     (if (no x)         nil
         (atag x)      (prn-tag-object x indent-level)
         (acons x)     (each child x (prn-nodes-helper child indent-level))
         (prn (indent-space indent-level) x)))

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
       (aif e!children (do (prn) (prn-nodes-helper it (+ 1 indent-level)) (pr (indent-space indent-level))))
       (prn "</" e!name ">")))

(prn-tag-object template)

(def tag (name args)
     (let res (attrs-and-children args)
       (build-tag name res!attrs res!children)))

(def element (name . args)
     (tag name args))

; convenience
(= e element)

(prn-tag-object (e "span" 'id "menu" 'class "golden" "This is my new span!!!!" "Stay away from it!!"))

(def alpop (x attr)
     "pop an element from an alist"
     (do1 (alref x attr)
          (pull [is (car _) attr] x)))

(= template
   (e "span" 'id "main"
      (e "ul" 'id "menu"
         (e "li" 'class "item" "Item1")
         (e "li" 'class "item" "Item2")
         (e "li" 'class "item" "Item3"))
      (e "div" "Regular div" "With stuff inside it")))

(prn-tag-object template)

(prn "span is: " span)

; define basic tags as functions like this:
; (def div args (tag "div" args))
(each tagname (list "div" "span" "html" "title" "head" "body" "p" "h1" "h2" "h3")
  (let tagsym (sym tagname)
    (eval `(def ,tagsym args (tag ,tagname args)))))

(def render-html args
     (prn-nodes-helper args))

(prn-tag-object (div (span "Hello")))

(prn "-------------")
(prn-tag-object
 (html
  (head (title "Hello world"))
  (body 
    (div 'id "content"
      (h1 "Main section")
      (p "First paragraph")))))

(mac deftag (name . body)
     "deftag allows you to define a tag-like function, arguments are implicit
     and defines the following variables:
     'attrs: attributes extracted from arguments
     'children: child nodes, extracted from arguments
     'attr: a function to get an attirubte from 'attrs
     'popattr: returns an attribute and removes it from attrs"
    `(def ,name args 
       (let res (attrs-and-children args)
        (with (attrs res!attrs children res!children)
          (with (popattr [alpop attrs _] attr [alref attrs _])
              ,@body)))))

(deftag items
      (e "ul" 'class attr!class
        (map [e "il" 'class attr!itemclass _] children)))

(prn "---------")
(prn "deftag demo")
(prn-tag-object (items 'class "list" 'itemclass "item" 
                       "item1" "item2"))
(prn-tag-object (items "item1" "item2"))

(deftag jscript
        "takes a list of js files and creates tags to include them"
        (map [e "script" 'type "text/javascript" 'src _] (flat children)))

(deftag csslink
        "takes a list of css files and creates tags to include them"
        (map [e "link" 'rel "stylesheet" 'type "text/css" 'href _] (flat children)))

(deftag page
    (html
      (head (title attr!title)
            (jscript attr!js)
            (csslink attr!css))
      (body children)))

(render-html (page 'title "Html template" 'js '("first.js" "second.js") (div "This is my content")))

(deftag blogpage
        (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))

(render-html (blogpage "This is my post"))

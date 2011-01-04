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

(def attrs-and-children-plumbing (xs (o result (obj attrs (queue))))
     (if xs
       (with (a (car xs) b (cadr xs) rest (cddr xs))
         (if (is-attr a) 
             (do (enq (list a b) result!attrs)
                 (attrs-and-children-plumbing rest result))
             (= result!children xs))))
     result)

(def attrs-and-children (xs)
     (let res (attrs-and-children-plumbing xs)
       (= res!attrs (qlist res!attrs))
       res))

(prn (attrs-and-children '(id "home" class "user")))
(prn (attrs-and-children '(id "home" class "user" "content" "content" "content")))

(def tag-object (name attrs children)
     (annotate 'tag (obj name name attrs attrs children children)))

(= template (tag-object "div" (tablist:obj id "main") "content"))

(prn "The tag name: " ((rep template) 'name))
(prn "The tag attrs: " ((rep template) 'attrs))
(prn "The tag childs: " ((rep template) 'children))

(def atag (x) (is (type x) 'tag))

(def indent-space (level)
     (string:n-of (* 2 level) " "))

(def prn-nodes-helper (x (o indent-level 0))
     (if (no x)         nill
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
       (if (and (no e!children) e!selfclose) (prn "/>") (prn ">"))
       (prn-nodes-helper e!children (+ 1 indent-level))
       (prn (indent-space indent-level) "</" e!name ">")))

(prn-tag-object template)

(def tag (name args)
     (let res (attrs-and-children args)
       (tag-object name res!attrs res!children)))

(def element (name . args)
     (tag name args))

; convenience
(= e element)

(prn-tag-object (e "span" 'id "menu" 'class "golden" "This is my new span!!!!" "Stay away from it!!"))

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
    `(def ,name args 
       (let res (attrs-and-children args)
        (with (attrs res!attrs children res!children)
              ,@body))))

(deftag items
      (e "ul" 
         (map [e "il" _] children)))

(prn "---------")
(prn "deftag demo")
(prn-tag-object
  (items "item1" "item2"))

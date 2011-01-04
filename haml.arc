; This is not a haml clone

; html tree nodes have attributes attached to them, to smilate that:
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

(thread:auto-reload "haml.arc")

(def tag-object (name attrs children)
     (annotate 'tag (obj name name attrs attrs children children)))

(= template (tag-object "div" (tablist:obj id "main") "content"))

(prn "The tag name: " ((rep template) 'name))
(prn "The tag attrs: " ((rep template) 'attrs))
(prn "The tag childs: " ((rep template) 'children))

(def atag (x) (is (type x) 'tag))

(def prn-nodes-helper (nodes)
     (if (no nodes)         nill
         (astring nodes)   (prn nodes)
         (atag nodes)      (prn-tag-object nodes)
         (acons nodes)     (each child nodes (prn-nodes-helper child))
             (prn nodes)))

(def pr-attrs (attrs)
     ; assumes attrs is an alist
     (each attr attrs
        (with 
          (key (string (attr 0))
           val (string "\"" (attr 1) "\""))
           (pr " " key "=" val ""))))

(def prn-tag-object (ttag)
     (let e (rep ttag)
       (pr "<" e!name)
       (pr-attrs e!attrs)
       (if (and (no e!children) e!selfclose) (prn "/>") (prn ">"))
       (prn-nodes-helper e!children)
       (prn "</" e!name ">")))

(prn-tag-object template)

(def ntag (name . args)
     (let res (attrs-and-children args)
       (tag-object name res!attrs res!children)))

(= e ntag) ; alias, e means element

(prn-tag-object (ntag "span" 'id "menu" 'class "golden" "This is my new span!!!!" "Stay away from it!!"))

(= template
   (e 'span 'id "main"
      (e 'div 'id "menu"
         (e 'il 'class "item" "Item1")
         (e 'il 'class "item" "Item2")
         (e 'il 'class "item" "Item3"))))

(prn-tag-object template)



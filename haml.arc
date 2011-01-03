; This is not a haml clone

; html tree nodes have attributes attached to them, to smilate that:
;
; (node-name @attr value @attr value child-node child-node child-node)
;
; For example:
;
;   (div @id "main" (span "text"))
; 
; A child node could be plain text or another html node
; attribute values are mostly strings

; a symbols is an attribute if it starts with @

(load "lib/util.arc")

(def is-attr (s)
     (and (asym s)
          (is ((string s) 0) #\@)))

(def attrs-and-children-raw (xs (o result (obj attrs (queue))))
     ; similar to pair, but only pairs when there's an attribute @attr
     (if xs
       (with (a (car xs) b (cadr xs) rest (cddr xs))
         (if (is-attr a) 
             (do (enq (list a b) result!attrs)
                 (attrs-and-children-raw rest result))
             (= result!children xs))))
     result)

(def attrs-and-children (xs)
     (let res (attrs-and-children-raw xs)
       (= res!attrs (qlist res!attrs))
       res))

(prn (attrs-and-children '(@id "home" @class "user")))
(prn (attrs-and-children '(@id "home" @class "user" "content" "content" "content")))

(thread:auto-reload "haml.arc")

(def tag-object (name attrs children)
     (annotate 'tag (obj name name attrs attrs children children)))

(= template (tag-object "div" (tablist:obj @id "main") "content"))

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
          (key (trim (string (attr 0)) 'front #\@)
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



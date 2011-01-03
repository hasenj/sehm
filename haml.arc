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

(def attrs-and-children (xs)
     ; similar to pair, but only pairs when there's an attribute @attr
     (if (no xs) nil
       (with (a (car xs) b (cadr xs) rest (cddr xs))
         (if (is-attr a) 
                 (cons (list a b) (attrs-and-children rest))
             (list xs)))))

(prn (attrs-and-children '(@id "home" @class "user" "content" "content" "content")))



(auto-reload "haml.arc")

(load "sehm.arc")

(def sep ()
     (prn) (prn "-----------") (prn))

(mac test-html body
     (let body (cons 'render-html body)
     `(do 
        (pr "arc>")
        (write ',body)
        (prn)
        ,body
        (sep))))

(def prepend-node (node lisp)
     (map [list node _] lisp))

(mac mass-test args
     (let newstatements (prepend-node 'test-html args)
     `(do ,@newstatements)))

(test-html (html "Test0"))

(mass-test

  (title "Title Element")

  (html
   (head (title "Hello world"))
   (body 
     (div 'id "content"
       (h1 "Main section")
       (p "First paragraph"))))

  (items 'class "list" 'itemclass "item" 
       "item1" "item2")
  (items "item1" "item2")
  (page 'title "Sample" "yes")
  (page 'title "Html template" 'js '("first.js" "second.js") (div "This is my content")))

(deftag blogpage
    (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))

(mass-test

  (blogpage "This is my post")
  (page 'title "Sample" 'js nil "yes")

  (page 'title "Test" 'js "js.js" 'css "css.css" 
      (e 'a 'href "google.com" "mylink")
      (p "Hello world" (e 'em "emphasis!!!") "did you see that?"))

  (page 'title "Test" 'js "js.js" 'css "css.css" 

      (p "Hello world" (e 'em "emphasis!!!") "did you see that?")
      (p "Btw, this is" (link "http://google.com" "mylink")))

  (row 1 2 3)
  (e 'style 'type "text/css" nil)
  (inlinecss)
  (inlinecss " div { margin: 20px; } ")
  (hacktag (p "Hello") 'class "rtl")
  )


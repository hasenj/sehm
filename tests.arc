(load "sehm.arc")

(def sep ()
     (prn) (prn "-----------") (prn))

(render-html
 (html
  (head (title "Hello world"))
  (body 
    (div 'id "content"
      (h1 "Main section")
      (p "First paragraph")))))

(sep)

(render-html (items 'class "list" 'itemclass "item" 
                       "item1" "item2"))
(sep)
(render-html (items "item1" "item2"))

(sep)
(render-html (page 'title "Sample" "yes"))
(sep)
(render-html (page 'title "Html template" 'js '("first.js" "second.js") (div "This is my content")))

(sep)
(deftag blogpage
        (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))
(render-html (blogpage "This is my post"))
(sep)
(render-html (page 'title "Sample" 'js nil "yes"))

(sep)

(render-html (page 'title "Test" 'js "js.js" 'css "css.css" 
                   (e 'a 'href "google.com" "mylink")
                   (p "Hello world" (e 'em "emhasis!!!") "did you see that?")))
(sep)

(render-html (page 'title "Test" 'js "js.js" 'css "css.css" 
                   
                   (p "Hello world" (e 'em "emhasis!!!") "did you see that?")
                   (p "Btw, this is" (link "http://google.com" "mylink"))))

(render-html (row 1 2 3))

## Sehm

sehm: *s*-*e*xpression based *h*tml *m*arkup for arc

Also: Arabic for:

* Arrow
* A unit of shares

## Basics

sehm is an engine for writing html using arc expressions.

    (div 'id "demo" 'class "wide"
         (span 'class "name" "Sehm"))

Renders into:

    <div id="demo" class="wide">
      <span class="name">
        Sehm
      </span>
    </div>

Here, 'div is a tag function. It parses its arguments into pairs of attributes and values, followed by a list of child nodes. Attributes are specified by symbols, so there's no ambiguity.

    (tag 'attr val 'attr val content content content)

The 'content' can be anything really, but typically it's either another node, a string, or a list of anything. It can be a list of lists, too. If a node is not a string or a tag, it will be output according to how 'pr prints it. If a node is nil, it's ignored.

Attributes values can also be anything, but typically they're strings. Attribute names *must* be symbols: that's how we know they are attributes. If the value passed to the attribute is nil, the attribute is ignored.

There are no macros involved here. 'div is a function, and the arguments passed to it are parsed by a function.

'div and other tag functions don't return a string. Instead, they return a tag/node object, which is just an annotated hashtable with the following fields:

    name: the tag name, e.g. "div"
    attrs: an associated list of attributes
    children: a list of child nodes

This object is rendered into a string using 'render-html which outputs the result to stdout. 

To capture the output as a string, use `tostring:render-html`

'div and 'span are convenience methods. Not all tags have methods defined in their names. To produce a generic tag, use the 'element function (or 'e for short):

    (e "div" 'class "myclass" "content" "content")

## Custom tags

You can create custom tags

Instead of writing:

    (div 'class "user"
      (span 'class "username" username)
      (span 'class "email" email))

You could write:

    (userdiv username email)

Where userdiv could be defined like this:

    (deftag userdiv
      (with (username (children 0) email (children 1))
        (div 'class "user"
          (span 'class "username" username)
          (span 'class "email" email))))

'deftag is a macro. It creates a function that automatically parses its arguments into 'attrs and 'children.
Since 'attrs is an alist, deftag also provides 'attr as a way of retriving an attributes, and 'popattr to retrive an attribute and remove it from the alist.

This means custom tags can process custom attributes:

    (deftag items
        (e "ul" 'class attr!class
           (map [e "li" 'class attr!itemclass _] children)))

This tag produces a ul with the class specified by 'class, and applies the class specified by 'itemclass to each li element.

    arc> (render-html (items 'class "list" 'itemclass "item" "first" "second" "third"))
    <ul class="list">
      <li class="item">
        first
      </li>
      <li class="item">
        second
      </li>
      <li class="item">
        third
      </li>
    </ul>
    nil

But because everything is a regular function, you can define custom tags as simple functions, without resorting to the deftag macro. The 'userdiv example from above can be defined simply as:

    (def userdiv (username email)
        (div 'class "user"
          (span 'class "username" username)
          (span 'class "email" email)))

And it would work just the same.

The point of deftag is that it parses the arguments passed to the function as attributes and children.

## Templates

Custom tags can serve as layout templates. 


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

Here, jscript and csslink are custom tags that produce the html biolerplates necessary to include .js and .css files.

'page is a custom tag that can also be thought of as a layout template. 

A layout template specified the general structure of a page and puts placeholders for things to be filled out later on. Because custom tags can process custom attributes, these attributes can be used to specify placeholders for templates.

Here's a usage example:

    arc> (render-html (page 'title "Html template" 'js '("first.js" "second.js") (div "This is my content")))
    <html>
      <head>
        <title>
          Html template
        </title>
        <script type="text/javascript" src="first.js"></script>
        <script type="text/javascript" src="second.js"></script>
      </head>
      <body>
        <div>
          This is my content
        </div>
      </body>
    </html>
    nil

Here, 'jscript and 'csslink are custom tags that are defined as regular functions

The 'page template processes 'js and 'css attributes, but it's very nil-tolerant. In this usage example, we didn't pass anything to 'css, and everything still worked as we expected.

Because a template is nothing more than a custom tag, and because tags are defined in terms of other tags, it follows that we can create templates based on other templates.


    (deftag blogpage
            (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))

Here, we're defining a specific kind of page, which fills most things for us.

    arc> (render-html (blogpage "This is my post"))
    <html>
      <head>
        <title>
          Blog post
        </title>
        <script type="text/javascript" src="blog.js"></script>
        <link rel="stylesheet" type="text/css" href="blog.css"></link>
      </head>
      <body>
        <div class="blogpost">
          This is my post
        </div>
      </body>
    </html>
    nil


# Sehm

sehm: S-Expression based Html Markup, for arc

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

### The syntax

Here, 'div is a tag function. It parses its arguments into pairs of attributes and values, followed by a list of child nodes. Attributes are specified by symbols, so there's no ambiguity.

    (tag 'attr val 'attr val content content content)

The 'content' can be anything really, but typically it's either another node, a string, or a list of anything. It can be a list of lists, too. If a node is not a string or a tag, it will be output according to how 'pr prints it. If a node is nil, it's ignored.

The content will be eventually normalized so that nils are removed, and lists of lists flattened.

So that:
   
    (div "a" "b" "c")

doesn't behave any different from:

    (div (list "a" "b" "c"))

The flattening doesn't actually affect the html tree hierarchy.

You can generate lists and include them as content:

    (div 'id "userlist" 
        (map [span _!username] user-list*))

Attributes values can be anything, but typically they're strings. Attribute names *must* be symbols: that's how we know they are attributes. If the value passed to the attribute is nil, the attribute is ignored.

It should be noted that the syntax above doesn't rely on macros. 'div is actually a function, and the arguments passed to it are parsed by a function.

'div and other tag functions don't return a string. Instead, they return a tag object (a node in the html tree), which is just an annotated hashtable with the following fields:

* name: the tag name, e.g. "div"
* attrs: an associated list of attributes
* children: a list of child nodes

This object is rendered into a string using `render-html` which outputs the result to stdout. 

To capture the output as a string, use `tostring:render-html`

`div` and `span` are convenience methods. Not all tags have methods defined in their names. To produce a generic tag, use the `element` function (or `e` for short):

    (e "div" 'class "myclass" "content" "content")

You can define a tag alias using the `deftagalias` macro:

    (deftagalias "section" "div")

Now you can use "section" as if it was "div":

    (section 'class "comments" 
        "Comments will be loaded here")

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
      (let (username email) children
        (div 'class "user"
          (span 'class "username" username)
          (span 'class "email" email))))

'deftag is a macro. It creates a function that automatically parses its arguments into 'attrs and 'children.
Since 'attrs is an alist, deftag also provides 'attr as a way of accessing attributes using `attr!something`

This means custom tags can process custom attributes:

    (deftag items
        (e "ul" 'class attr!class
           (map [e "li" 'class attr!itemclass _] children)))

This tag produces a `ul` with the class specified by 'class, and applies the class specified by 'itemclass to each `li` element.

    arc> (render-html 
            (items 'class "list" 'itemclass "item" 
                "first" "second" "third"))
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

The point of deftag is that it parses the arguments passed to the function as attributes and children. It also normalizes the 'children' list as discussed above.

It can be sometimes useful to remove or add attributes to `attrs`, so 'deftag defines 'popattr to retrive an attribute and remove it from 'attrs, and 'addattr which accepts any number of `'attr val` arguments and adds them as new attributes to 'attrs.

We can then pass `attrs` to the low level `tag` function to create 'proxy' tags that autofill common attributes.

For example, a table tag with cellpadding and cellspacing set to 0 automatically:

    (deftag tab
        (addattr 'cellpadding 0 'cellspacing 0)
        (tag 'table attrs children))

This means We can supply extra attributes to the `tab` function if needed, and they will be passed on to the table tag.

    arc> (render-html (tab))
    <table cellspacing="0" cellpadding="0"></table>
    nil
    arc> (render-html (tab 'border 5))
    <table cellspacing="0" cellpadding="0" border="5"></table>
    nil

As you may have noticed, the `tag` function takes 3 arguments: the tag name, an alist of attributes, and a list of children.

Normalizing the 'children' list can actually be very useful, it allows us to just assume that 'children' is a flat list without caring about how it was generated.

For example, consider:

    (deftag jscript
            (map [e "script" 'type "text/javascript" 'src _] children))

Here, jscript takes a list of paths to .js files and renders the html boilerplate necessary to "import" them.

We can use it like this:

    (jscript "jquery.js" "comments.js" "coffee.js")

Or like this:

    (jscript (get-js-files))

And in both cases it would work in the same way.

If `get-js-files` returns an empty list, it will be as if you called `jscript` with no arguments:

    (jscript)

Which wouldn't do anything.

We can define a similar tag for css files:

    (deftag csslink
            (map [e "link" 'rel "stylesheet" 'type "text/css" 'href _] children))

## Templates

Because there are no artifical restriction on attributes, custom tags can serve as layout templates, with attributes serving as placeholders:

    (deftag page
        (html
          (head (title attr!title)
                (jscript attr!js)
                (csslink attr!css))
          (body children)))

`page` is a custom tag that can also be thought of as a layout template.

The point of a template is to specify the general structure of a page, while putting placeholders for things to be filled out later on. 

Because custom tags can process custom attributes, these attributes can be used to specify placeholders for templates.

For example, if we look at this expression inside the `page` template:

    (title attr!title)

The attribute denoted by 'title is passed to the `title` tag.

    arc> (render-html (page 'title "Html template" 'js '("first.js" "second.js") (div "This is my content")))
    <html>
      <head>
        <title>Html template</title>
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

The `page` template processes `js` and `css` attributes, but it's very nil-tolerant. In the above example, we didn't pass anything to `css`, and everything still worked as we expected.

Because a template is nothing more than a custom tag, and because tags are defined in terms of other tags, it follows that we can create templates based on other templates.

    (deftag blogpage
            (page 'title "Blog post" 'js "blog.js" 'css "blog.css" (div 'class "blogpost" children)))

Here, we're defining a specific kind of page, which fills most things for us.

    arc> (render-html (blogpage (p "In this post we discuss" (e "a" 'href "http://arclanguage.org" "Arc"))))
    <html>
      <head>
        <title>Blog post</title>
        <script type="text/javascript" src="blog.js"></script>
        <link rel="stylesheet" type="text/css" href="blog.css" />
      </head>
      <body>
        <div class="blogpost">
          <p>In this post we discuss <a href="http://arclanguage.org">Arc</a></p>
        </div>
      </body>
    </html>
    nil

## Batteries included (kinda)

sehm attempts to include a number of useful custom tags.

* jscript: for including a bunch of js paths
* csslink: for including a bunch of css paths
* inlinecss: a style tag where you can write css
* inlinejs: a script tag with js code inside
* row: stacks items horiztonally inside a table
* col: stacks items vertically using divs (no tables)
* link: takes an href and a string to create an html link.
* page: a very simple page skeleton 

## More examples

The file 'tests.arc' provides a few usage examples. The output of tests.arc simulates a command prompt so that should make it easier to read.


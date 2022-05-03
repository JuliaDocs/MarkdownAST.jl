# This example demonstrates the conversion from the Markdown standard library AST to the
# MarkdownAST AST representation.
using MarkdownAST: MarkdownAST, Node
using Markdown: @md_str

doc = md"""
# Example document

Lorem ipsum *emphasis here* dolores **strong** amet.

The following tests an empty heading labels:

##

---

> This is a block quote.
>
> This paragraph contains [links](link/url/) and ![images](image.jpeg).

---

> One-line block quote, followed by an empty block quote.

>

Inline mathematics (``x^2``) and display math:

```math
x^2
```

!!! warn "Admonition title"

    Admonition content.

    > Admonitions contain block content.

* Additional AST elements include..
* Autolinks: <https://autolink.com>
* More complex links: [X **Y** Z](url/)
* Footnotes[^footnote]

Tables get converted too:

| Column One | Column Two | Column Three |
|:---------- | ---------- |:------------:|
| Row `1`    | Column `2` |              |
| *Row* 2    | **Row** 2  | Column ``3`` |

[^footnote]: Footnote definition.
"""

# Convert the standard library AST into MarkdownAST
doc_mdast = convert(Node, doc)

# Print the AST into stdout
MarkdownAST.showast(doc_mdast)

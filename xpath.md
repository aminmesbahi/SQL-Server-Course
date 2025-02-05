Below are several XQuery and XPath examples ranging from beginner to advanced, using your 

books.xml

 file.

--------------------------------------------------
Beginner XPath Examples:

1. Select all book titles:
 XPath Query:  
  /catalog/book/title

2. Select all authors:
 XPath Query:
  /catalog/book/author

3. Count the number of books:
 XPath Query:
  count(/catalog/book)

4. Select books in the "Computer" genre:
 XPath Query:
  /catalog/book[genre = 'Computer']

--------------------------------------------------
Intermediate XPath Examples:

5. Select books with a price higher than 20:
 XPath Query:
  /catalog/book[price > 20]

6. Select the title and publish date for books published after 2000-12-05:
 XPath Query:
  /catalog/book[publish_date > '2000-12-05']/(title, publish_date)

7. Select books with titles containing the text "Guide":
 XPath Query:
  /catalog/book[contains(title, 'Guide')]

--------------------------------------------------
Beginner XQuery Examples:

8. Return all book titles using XQuery:
 XQuery:
  for $b in doc("books.xml")//book
  return $b/title

9. Return title and author for each book:
 XQuery:
  for $b in doc("books.xml")//book
  return
   <info>
    <title>{ $b/title/text() }</title>
    <author>{ $b/author/text() }</author>
   </info>

--------------------------------------------------
Intermediate XQuery Examples:

10. Filter books with price less than or equal to 10 and return as XML:
 XQuery:
  for $b in doc("books.xml")//book
  where xs:decimal($b/price) <= 10
  return
   <book id="{ $b/@id }">
    { $b/title }
    { $b/author }
   </book>

11. Return books sorted by publish date (ascending):
 XQuery:
  for $b in doc("books.xml")//book
  order by xs:date($b/publish_date)
  return $b

--------------------------------------------------
Advanced XQuery Examples:

12. Group books by genre and count the number in each group:
 XQuery (using FLWOR and grouping):
  for $g in distinct-values(doc("books.xml")//book/genre)
  let $books := doc("books.xml")//book[genre = $g]
  return
   <genre name="{$g}">
    <count>{ count($books) }</count>
    <books>{ $books }</books>
   </genre>

13. Return books with detailed info and an extra element showing if the price is considered "Low" (<15), "Medium" (15-30) or "High" (>30):
 XQuery:
  for $b in doc("books.xml")//book
  let $price := xs:decimal($b/price)
  let $range :=
   if ($price < 15) then 'Low'
   else if ($price <= 30) then 'Medium'
   else 'High'
  return
   <book id="{ $b/@id }">
    <title>{ $b/title }</title>
    <author>{ $b/author }</author>
    <price range="{$range}">{ $b/price }</price>
    <publish_date>{ $b/publish_date }</publish_date>
   </book>

14. Advanced XPath: Using union to return all titles and genres in one result set:
 XPath Query:
  /catalog/book/title | /catalog/book/genre

--------------------------------------------------
Notes:

• Replace doc("books.xml") with the appropriate file path if needed.
• These examples assume your XML root is <catalog> and each <book> element contains common subelements.
• Run these queries using an XQuery processor or an XML-enabled IDE (such as VS Code with an XML/XQuery extension).

These examples provide a progressive tutorial from simple XPath selections to advanced XQuery grouping and conditional logic.
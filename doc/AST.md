## Metalua AST

### Tokens

| Statements |                                                              |
| :--------- | :----------------------------------------------------------- |
| Do         | `do b while e end `                                          |
| While      | `while e do b end `                                          |
| Repeat     | `repeat b until e`                                           |
| Fornum     | `for i = 1, n do b end`                                      |
| Forin      | `for i1, i2... in e1, e2... do b end`                        |
| If         | `if exp then block {elseif exp then block} [else block] end` |
| Set        | `lhs1, lhs2... = e1, e2...`                                  |
| Local      | `local i1, i2... = e1, e2...`                                |
| Localrec   | `local function() b end`                                     |

| Expressions                            |                        |
| :------------------------------------- | :--------------------- |
| Nil                                    | `nil`                  |
| Dots                                   | `...`                  |
| True                                   | `true`                 |
| False                                  | `false`                |
| (Boolean{truefalse})                   | `false`                |
| Number{n}                              | `3`                    |
| String{s}                              | `'hello'`              |
| Function{ { ident\* Dots? } b }        | `function(a, ...) end` |
| Table{ ( `Pair{ expr expr } expr )\* } | `{a = 2, b = 3}`       |
| Op opid expr expr? }                   | `3 + 2`                |
| Stat{ b, e }                           | `nil`                  |
| Paren{ e }                             | `()`                   |

| Apply                                     |            |
| :---------------------------------------- | :--------- |
| Call{ expr expr\* }                       | `f()`      |
| Invoke{ expr `String{ <string> } expr\* } | `v:draw()` |

| LHS                |       |
| :----------------- | :---- |
| Id{id}             | `f`   |
| Index{ expr expr } | `t.a` |

#### Tree

- Leaf
  - constants, literals (Number, String, Nil, Boolean)
  - identifiers
  - Index

#### Validations

(tree, scope) -> bool, string

##### scope

under what conditions should it be checked
partial match on tree path
e.g. is this a Set inside a Table

```bnf
chunk ::= {stat [`;´]} [laststat[`;´]]

block ::= chunk

stat ::=  varlist1 `=´ explist1  |
          functioncall  |
          do block end  |
          while exp do block end  |
          repeat block until exp  |
          if exp then block {elseif exp then block} [else block] end  |
          for Name `=´ exp `,´ exp [`,´ exp] do block end  |
          for namelist in explist1 do block end  |
          function funcname funcbody  |
          local function Name funcbody  |
          local namelist [`=´ explist1]

laststat ::= return [explist1]  |  break

funcname ::= Name {`.´ Name} [`:´ Name]

varlist1 ::= var {`,´ var}

var ::=  Name  |  prefixexp `[´ exp `]´  |  prefixexp `.´ Name

namelist ::= Name {`,´ Name}

explist1 ::= {exp `,´} exp

exp ::=  nil  |  false  |  true  |  Number  |  String  |  `...´  |
          function  |  prefixexp  |  tableconstructor  |  exp binop exp  |  unop exp

prefixexp ::= var  |  functioncall  |  `(´ exp `)´

functioncall ::=  prefixexp args  |  prefixexp `:´ Name args

args ::=  `(´ [explist1] `)´  |  tableconstructor  |  String

function ::= function funcbody

funcbody ::= `(´ [parlist1] `)´ block end

parlist1 ::= namelist [`,´ `...´]  |  `...´

tableconstructor ::= `{´ [fieldlist] `}´

fieldlist ::= field {fieldsep field} [fieldsep]

field ::= `[´ exp `]´ `=´ exp  |  Name `=´ exp  |  exp

fieldsep ::= `,´  |  `;´

binop ::= `+´  |  `-´  |  `*´  |  `/´  |  `^´  |  `%´  |  `..´  |
          `<´  |  `<=´  |  `>´  |  `>=´  |  `==´  |  `~=´  |
          and  |  or

unop ::= `-´  |  not  |  `#´

```

### in-app

```haskell
data TokenType = kw_single | kw_multi | number | string | identifier
```

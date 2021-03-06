/*
 * PEGjs for a "Pl-0" like language
 * Used in ULL PL Grado de Informática classes
 */

{
  var tree = function(f, r) {
    if (r.length > 0) {
      var last = r.pop();
      var result = {
        type:  last[0],
        left: tree(f, r),
        right: last[1]
      };
    }
    else {
      var result = f;
    }
    return result;
  }
}

program = b:block { b.name = {type: 'ID', value: "$main"}; b.params = []; return b;}

block = cD:constantDeclaration? vD:varDeclaration? fD:functionDeclaration* st:st
          {
            let constants = cD? cD : [];
            let variables = vD? vD : [];
            return {
              type: 'BLOCK',
              constants: constants,
              variables: variables,
              functions: fD,
              main: st
            };
          }

constantDeclaration = CONST id:ID ASSIGN n:NUMBER rest:(COMMA ID ASSIGN NUMBER)* SC
                        {
                          let r = rest.map( ([_, id, __, nu]) => [id.value, nu.value] );
                          return [[id.value, n.value]].concat(r)
                        }

varDeclaration = VAR id:ID rest:(COMMA ID)* SC
                    {
                      let r = rest.map( ([_, id]) => id.value );
                      return [id.value].concat(r)
                    }

functionDeclaration = FUNCTION id:ID LEFTPAR !COMMA p1:ID? r:(COMMA ID)* RIGHTPAR SC b:block SC
      {
        let params = p1? [p1] : [];
        params = params.concat(r.map(([_, p]) => p));
        //delete b.type;
        return Object.assign({
          type: 'FUNCTION',
          name: id,
          params: params,
        }, b);

      }

st     = CL s1:st? r:(SC st)* SC* CR {
               //console.log(location()) /* atributos start y end */
               let t = [];
               if (s1) t.push(s1);
               return {
                 type: 'COMPOUND', // Chrome supports destructuring
                 children: t.concat(r.map( ([_, st]) => st ))
               };
            }
       / IF e:assign THEN st:st ELSE sf:st
           {
             return {
               type: 'IFELSE',
               c:  e,
               st: st,
               sf: sf,
             };
           }
       / IF e:assign THEN st:st
           {
             return {
               type: 'IF',
               c:  e,
               st: st
             };
           }

        / DO st:st WHILE a:assign {
              return { type: 'DOWHILE', st: st, c:a }
        }

       / WHILE a:assign DO st:st {
             return { type: 'WHILE', c: a, st: st };
           }
       / RETURN a:assign? {
             return { type: 'RETURN', children: a? [a] : [] };
           }

      /*
        * For inicio:final{
        *....}
        */

       / FOR a:NUMBER PUNTOS b:NUMBER st:st {
            return { type: 'FOR', comiezo: a, final: b, indice: a, st: st };
          }


        /*
        * a++;
        *
        */

       / id:ID INCREMENTO SC st:st {
            return { type: 'INC', i:id, st: st};
         }

        /*
        *a--;
        *
        */

       / id:ID DECREMENTO SC st:st {
            return {type: 'DEC', i:id, st: st};
        }

        /*
         *<<hola<<;
         *
         */

       / PRINT id:ID PRINT SC st:st{
          return { type: 'PRINT', i:id, st: st};
        }

        /*
         * >>a>>;
         *
         */

       / SCAN id:ID SCAN SC st:st {
          return { type: 'SCAN', i:id, st: st};
        }
       / assign

assign = i:ID ASSIGN e:cond
            { return {type: '=', left: i, right: e}; }
       / array ASSIGN NUMBER SC st:st?
       / array ASSIGN array SC st:st?
       / cond

cond = l:exp op:COMP r:exp { return { type: op, left: l, right: r} }
     / exp

exp    = t:term   r:(ADD term)*   { return tree(t,r); }
term   = f:factor r:(MUL factor)* { return tree(f,r); }


factor = NUMBER
       / f:ID LEFTPAR a:assign? r:(COMMA assign)* RIGHTPAR
         {
           let t = [];
           if (a) t.push(a);
           return {
             type: 'CALL',
             func: f,
             arguments: t.concat(r.map(([_, exp]) => exp))
           }
         }
       / ID
       / LEFTPAR t:assign RIGHTPAR   { return t; }

array = id:ID LEFTCOR a:NUMBER RIGHTCOR r:(LEFTCOR NUMBER RIGHTCOR)*  {
            return { type: 'ARRAY', tamano: a, rr: r};
        }

_ = $[ \t\n\r]*

ASSIGN   = _ op:'=' _  { return op; }
ADD      = _ op:[+-] _ { return op; }
MUL      = _ op:[*/] _ { return op; }
LEFTPAR  = _"("_
RIGHTPAR = _")"_
LEFTCOR  = _"["_
RIGHTCOR = _"]"_
CL       = _"{"_
CR       = _"}"_
SC       = _";"+_
COMMA    = _","_
PUNTOS   = _":"_
INCREMENTO = "++"
DECREMENTO = "--"
COMP     = _ op:("=="/"!="/"<="/">="/"<"/">") _ {
               return op;
            }
IF       = _ "if" _
THEN     = _ "then" _
ELSE     = _ "else" _
PRINT    = "<<"
SCAN     = ">>"
WHILE    = _ "while" _
FOR      = _ "for" _
DO       = _ "do" _
RETURN   = _ "return" _
VAR      = _ "var" _
CONST    = _ "const" _
FUNCTION = _ "function" _
ID       = _ id:$([a-zA-Z_][a-zA-Z_0-9]*) _
            {
              return { type: 'ID', value: id };
            }
LETRA       = id:$([a-zA-Z_][a-zA-Z_0-9]*)
            {
              return { type: 'ID', value: id };
            }
NUMBER   = _ digits:$[0-9]+ _
            {
              return { type: 'NUM', value: parseInt(digits, 10) };
            }

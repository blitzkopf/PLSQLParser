# set PYTHONPATH=..\..\..\build\generated-src\antlr\main
import sys
from antlr4 import *
from PLSQLLexer import PLSQLLexer
from PLSQLParser import PLSQLParser
from PLSQLParserListener import PLSQLParserListener
import pprint
import collections
pp=pprint.PrettyPrinter(indent=2,depth=10)

def tabtree():
    return collections.defaultdict(tabtree)

links=tabtree()

class FromFinder(PLSQLParserListener):
    def __init__(self):
        super().__init__()
        self.withs=[]

    def enterDml_table_def(self,ctx):
        #print("There is a Dml_table_def")
        #pp.pprint(ctx)
        #print(ctx.getText())
        self.dm_table = ctx.getText().upper()
        ident = ctx.ident()
        #pp.pprint(ident)
        #print(ident.getText())

    def enterSubquery_factoring_clause(self,ctx):  ## WITH statement
        idents = ctx.ident()
        self.withs = []
        for id in idents:
            self.withs.append(id.getText().upper())


    def enterQuery_table_def(self,ctx):
        #print("There is a Query_table")
        #pp.pprint(ctx)
        #print(ctx.getText())
        #ident = ctx.ident()
        fullname = ctx.getText().upper()
        schema = ctx.ident(0).getText().upper()
        try:
            name = ctx.ident(1).getText().upper()
            dblink = ctx.dblink().getText().upper()
            links[dblink][schema][name]=fullname
        except AttributeError:
            pass
        # pp.pprint(dblink)
        try:
            if not fullname in self.withs and fullname != 'DUAL':
                print('"'+fullname+'" -> "'+self.dm_table+'"')
            #else:
            #    print("local reference:"+fullname)
        except (AttributeError,TypeError):
            pass
        #print(ident.getText())
    
    def exitInsert_statement(self,ctx):
        self.dm_table = None
        self.withs = []

def main(argv):
    input = FileStream(argv[1],'iso8859-1')
    lexer = PLSQLLexer(input)
    stream = CommonTokenStream(lexer)
    parser = PLSQLParser(stream)
    tree = parser.script()
    printer = FromFinder()
    walker = ParseTreeWalker()
    print("""
    strict digraph LCR_DATA {
    label = LCR_DATA
    rankdir=LR;
    node [ style=filled, fillcolor=white];
    """)

    walker.walk(printer, tree)
    #
    #pp.pprint(tree)
    for link in links.keys():
        print(f""" 
            subgraph "cluster_{link}" {{
            label = "{link}";
            style=filled;
            color=lightblue;""")
        for schema in links[link].keys():
            print(f""" 
                subgraph "cluster_{schema}" {{
                label = "{schema}";
                style=filled;
                color=darkolivegreen2;""")
            for name in links[link][schema].keys():
                print('"'+links[link][schema][name]+'"')
            print("}")
        
    
        print("}")
    print("}")
 
if __name__ == '__main__':
    main(sys.argv)
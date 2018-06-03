x = fun { print 123 print y print max }
x()
max = 18_____446____744__073__709____551_____616______
x()
x = 20
print x
y = fun { print 321 }
y()
nest = fun { nest = fun { nest = fun { print 8008135 } } }
nest()
nest()
nest()
nest()
nest()
func = 100
print func
funct = fun
if((func == 100) == 0) { funct = fun print 123 }
else { funct = fun print 5001 }
funct()
funct()
minus1 = 18_446_744_073_709_551_615
fib = fun
    if (n == 0) print a
    else {
        a = afirst + asecond
        asecond = afirst
        afirst = a
        n = n + minus1
        fib()
    }
n = 91
afirst = 1
asecond = 1
a = 1
fib()
print afirst
print asecond
print n

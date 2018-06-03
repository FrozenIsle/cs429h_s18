recur = 0 + fun{ if(b == 5){} else { print a b = b + 1 recur()}  } + 3*0
a = 1
b = 0
recur()

rec2 = fun { print 0 }
rec2 = 5
print rec2

rec2 = fun { rec3 = fun{ if(c == 3){} else { print d b = 0 recur() c = c + 1 rec3()}  } }
rec2()
d = 2
c = 0
rec3()

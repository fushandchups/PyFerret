# To be run in python after importing and starting pyferret
# such as from running "pyferret -python"

from __future__ import print_function

import sys ; sys.ps1 = '' ; sys.ps2 = ''
print()

print(">>> dsetnames = ['./data/ens1.nc', './data/ens2.nc', './data/ens3.nc', './data/ens4.nc']")
dsetnames = ['./data/ens1.nc', './data/ens2.nc', './data/ens3.nc', './data/ens4.nc']

print(">>> onefileagg = pyferret.FerAggDSet(name='onefileagg', dsets=dsetnames[-1:], along='E')")
onefileagg = pyferret.FerAggDSet(name='onefileagg', dsets=dsetnames[-1:], along='E')
print(">>> pyferret.showdata()")
pyferret.showdata()
print(">>> print str(onefileagg)")
print(str(onefileagg))
print(">>> onefileagg.close()")
onefileagg.close()
print(">>> pyferret.showdata()")
pyferret.showdata()
print(">>> print str(onefileagg)")
print(str(onefileagg))

print(">>> twofileagg = pyferret.FerAggDSet(name='twofileagg', dsets=dsetnames[-2:], along='E', hide=True)")
twofileagg = pyferret.FerAggDSet(name='twofileagg', dsets=dsetnames[-2:], along='E', hide=True)
print(">>> pyferret.showdata()")
pyferret.showdata()
print(">>> print str(twofileagg)")
print(str(twofileagg))
print(">>> twofileagg.close()")
twofileagg.close()
print(">>> pyferret.showdata()")
pyferret.showdata()
print(">>> print str(twofileagg)")
print(str(twofileagg))

print(">>> fourfiles = pyferret.FerAggDSet(name='fourfiles', dsets=dsetnames, along='E')")
fourfiles = pyferret.FerAggDSet(name='fourfiles', dsets=dsetnames, along='E')
print(">>> pyferret.showdata()")
pyferret.showdata()
print(">>> fourfiles.show()")
fourfiles.show()
print(">>> print str(fourfiles)")
print(str(fourfiles))
print(">>> fourfiles.getdsetnames()")
fourfiles.getdsetnames()
print(">>> fourfiles.getdsets()")
fourfiles.getdsets()

print(">>> fourfiles.SST.showgrid()")
fourfiles.SST.showgrid()

print(">>> fourfiles.close()")
fourfiles.close()
print(">>> print str(fourfiles)")
print(str(fourfiles))
print(">>> fourfiles.getdsetnames()")
fourfiles.getdsetnames()
print(">>> fourfiles.getdsets()")
fourfiles.getdsets()
print(">>> pyferret.showdata()")
pyferret.showdata()


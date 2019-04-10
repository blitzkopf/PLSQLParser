select * from dual 
cross join 
( table(base.pack.tprice(
               acc.T1,
               trunc(sysdate),
               null,
               null,
               null,
               'V'
             )
		)
	)
         
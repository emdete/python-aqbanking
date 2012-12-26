#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = "M. Dietrich <mdt@pyneo.org>"
__version__ = "prototype"
__copyright__ = "Copyright (c) 2008 M. Dietrich"
__license__ = "GPLv3"

from datetime import datetime, timedelta
from aqbanking import BankingRequestor, BLZCheck

'''
see file:///usr/share/doc/libaqbanking-doc/aqbanking.html/group__G__AB__BANKING.html
'''


def main(pin_name, pin_value, config_dir, bank_code, account_numbers, *args):
	bc = BLZCheck()
	for tx in BankingRequestor(
		pin_name=pin_name, # the name is some internal aqbanking magic. its shown in the log when wrong
		pin_value=pin_value,
		config_dir=config_dir,
		bank_code=bank_code,
		account_numbers=account_numbers.split(';'),
	).request_transactions(from_time=datetime.now()-timedelta(days=90), to_time=datetime.now(), ):
		if 'remote_bank_code' in tx:
			b = bc.get_bank(tx['remote_bank_code'])
			if b:
				for n, v in b.items():
					tx['remote_' + n] = v
		b = bc.get_bank(tx['local_bank_code'])
		if b:
			for n, v in b.items():
				tx['local_' + n] = v
		#print tx
		print u' '.join([unicode(n) for n in tx.values()])

if __name__ == '__main__':
	from sys import argv
	main(*argv[1:])
# vim:tw=0:nowrap

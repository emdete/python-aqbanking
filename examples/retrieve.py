#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = "M. Dietrich <mdt@pyneo.org>"
__version__ = "prototype"
__copyright__ = "Copyright (c) 2008 M. Dietrich"
__license__ = "GPLv3"

from datetime import datetime, timedelta
from aqbanking import BankingRequestor, BLZCheck

import argparse
import os

# see /usr/share/doc/libaqbanking-doc/aqbanking.html/group__G__AB__BANKING.html


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pin', default=None,
                    help=("your PIN. note that giving passwords as "
                          "command-line args is usually an extremely bad "
                          "idea. omit for an interactive prompt."))
    ap.add_argument('--pin-name', default=None,
                    help=("needed by aqbanking internally. "
                          "usually something along the lines of "
                          "PIN_{bank_code}_{user_id}"))
    ap.add_argument('--config-dir', default=os.path.expanduser('~/.aqbanking'),
                    help=("your aqbanking config dir, where the bank account "
                          "in question has been fully configured."
                          "defaults to ~/.aqbanking."))
    ap.add_argument('--bank-code', required=True,
                    help=("your bank code (german: BLZ)."))
    ap.add_argument('--account-number', required=True,
                    help=("your account number. split using commata."))

    args = ap.parse_args()

    if args.pin is None != args.pin_name is None:
        ap.error("--pin and --pin-name require each other.")

    if args.pin:
        args.pin = args.pin.encode()
    if args.pin_name:
        args.pin_name = args.pin_name.encode()

    bc = BLZCheck()
    requestor = BankingRequestor(
        pin_name=args.pin_name,
        pin_value=args.pin,
        config_dir=args.config_dir.encode(),
        bank_code=args.bank_code.encode(),
        account_numbers=args.account_number.encode().split(b','))

    for tx in requestor.request_transactions(
            from_time=datetime.now()-timedelta(days=90),
            to_time=datetime.now()):

        if 'remote_bank_code' in tx:
            b = bc.get_bank(tx['remote_bank_code'])
            if b:
                for n, v in b.items():
                    tx['remote_' + n] = v
        b = bc.get_bank(tx['local_bank_code'])
        if b:
            for n, v in b.items():
                tx['local_' + n] = v

        # print tx
        def printablevalues(tx):
            for k, v in sorted(tx.items()):
                import six
                if isinstance(v, six.binary_type):
                    yield v.decode('utf-8', errors='ignore')
                elif isinstance(v, six.text_type):
                    yield v
                else:
                    yield str(v)

        print(" ".join([v for v in printablevalues(tx)]))


if __name__ == '__main__':
    main()

# vim:tw=0:nowrap

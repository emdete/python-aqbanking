#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = "M. Dietrich <mdt@pyneo.org>"
__version__ = "prototype"
__copyright__ = "Copyright (c) 2008 M. Dietrich"
__license__ = "GPLv3"

from datetime import datetime
from os.path import exists
from thread import start_new_thread
from gobject import timeout_add, source_remove
from aqbanking import BankingRequestor
from pyneo.cfg_support import ConfigParser
from pyneo.db_support import Database, BankAccountTransaction
from pyneo.dbus_support import FallbackObject, NotifyObject, Empty, url_from_obj_path, DBusException
from pyneo.log_support import LOG_ERR, LOG_WARNING, LOG_INFO, LOG_DEBUG, LOG
from pyneo.interfaces import Authorized, Storage, KeyRing, Entry, Powered

'''
see file:///usr/share/doc/libaqbanking-doc/aqbanking.html/group__G__AB__BANKING.html

alias -- DB="dbus-send --system --print-reply --type=method_call --dest=org.pyneo.pyneod"
DB /org/pyneo/Bank org.pyneo.KeyRing.SetPin string:1234567890
DB /org/pyneo/Bank org.pyneo.Powered.SetPower string:sample boolean:true
DB /org/pyneo/Bank org.pyneo.Powered.Fake
DB /org/pyneo/bank/BankAccountTransaction/803a0e5e201800e704becfd2043c540d org.pyneo.Entry.GetContent
'''


class BLZCheck(object):
	def __init__(self, filename='/var/lib/ktoblzcheck1/bankdata.txt'):
		self.blz_mapping = self._read(filename)

	def _read(self, filename):
		blz_mapping = dict()
		if exists(filename):
			f = open(filename)
			l = f.readlines()
			f.close()
			for b in l:
				b = unicode(b, 'iso8859-15', 'replace')
				b = b.strip().split('\t')
				blz_mapping[b[0]] = dict(zip(('bank_code', 'bank_validationmethod', 'bank_name', 'bank_location', ), b))
		return blz_mapping

	def get_bank(self, bank_code):
		if bank_code in self.blz_mapping:
			b = self.blz_mapping[bank_code]
			return b


class _BankAccountTransaction(FallbackObject, Entry):
	object_path = '/org/pyneo/bank/BankAccountTransaction'
	def __init__(self, bus, bank):
		FallbackObject.__init__(self,
			object_path=self.object_path,
			conn=bus,
			)
		self.bank = bank

	@classmethod
	def _dbus_path(clazz, ui):
		return '%s/%s'% (clazz.object_path, ui, )

	def get_content(self, rel_path, ok_cb, error_cb):
		try:
			LOG(LOG_DEBUG, __name__, 'get_content', rel_path)
			rel_path = rel_path.split('/')
			assert len(rel_path) == 2
			ui = rel_path[1]
			db = BankAccountTransaction()
			tx = db.get(ui)
			ok_cb(tx)
		except Exception, e:
			LOG(LOG_ERR, __name__, 'get_content', e)
			error_cb(e)

	def delete(self, rel_path, ok_cb, error_cb):
		rel_path = rel_path.split('/')
		assert len(rel_path) == 2
		ui = int(rel_path[1])

	def change(self, m, rel_path, ok_cb, error_cb):
		try:
			rel_path = rel_path.split('/')
			assert len(rel_path) == 2
			ui = rel_path[1]
			db = BankAccountTransaction()
			state = m.pop('state')
			if m:
				raise Exception('wont change a bank transaction but their state')
			count = db.update_state(ui, state)
			if count != 1:
				raise Exception('changed %d entries'% count)
			ok_cb()
		except Exception, e:
			LOG(LOG_ERR, __name__, 'change', e)
			error_cb(e)


class Daemon(NotifyObject, KeyRing, Authorized, Powered, Storage, ):
	def __init__(self, bus, config):
		NotifyObject.__init__(self,
			object_path='/org/pyneo/Bank',
			conn=bus,
			)
		Database.init(config.get('database')) # TODO: fix path!
		self.bc = BLZCheck()
		self.bat = _BankAccountTransaction(bus, self)
		self.br = None
		self.pin = config.get('pin_value')
		self.config = config
		self.timer = None
		LOG(LOG_DEBUG, __name__, '__init__')

	def _get_br(self):
		if not self.br:
			self.br = BankingRequestor(
				pin_name=self.config.get('pin_name'), # the name is some internal aqbanking magic. its shown in the log when wrong
				pin_value=self.pin,
				config_dir=self.config.get('config_dir'),
				bank_code=self.config.get('bank_code'),
				account_numbers=self.config.get('account_numbers').split(';'),
				)
		return self.br

	def _requester(self, *args):
		try:
			LOG(LOG_DEBUG, __name__, '_requester start')
			db = BankAccountTransaction()
			from_time = db.last()
			LOG(LOG_DEBUG, __name__, '_requester from', from_time)
			for tx in self._get_br().request_transactions(from_time=from_time, to_time=datetime.now(), ):
				if 'remote_bank_code' in tx:
					b = self.bc.get_bank(tx['remote_bank_code'])
					if b:
						for n, v in b.items():
							tx['remote_' + n] = v
				b = self.bc.get_bank(tx['local_bank_code'])
				if b:
					for n, v in b.items():
						tx['local_' + n] = v
				LOG(LOG_DEBUG, __name__, '_requester inserting: ', tx)
				try:
					if db.insert(**tx):
						dbus_url = url_from_obj_path(_BankAccountTransaction._dbus_path(tx['ui']))
						self.New({dbus_url: Empty})
						LOG(LOG_INFO, 'new transaction', tx['ui'])
					else:
						LOG(LOG_DEBUG, 'old transaction', tx['ui'])
				except Exception, e:
					LOG(LOG_ERR, __name__, '_requester', e)
			db.commit()
			self.timer = timeout_add(self.config.getint('poll_interval') * 1000, self._starter)
		except Exception, e:
			LOG(LOG_ERR, __name__, '_requester', e)
			self.timer = timeout_add(self.config.getint('poll_interval') * 1000 * 10, self._starter)
		LOG(LOG_DEBUG, __name__, '_requester done')

	def _starter(self, *args):
		if self.pin:
			start_new_thread(self._requester, args)

	# Powered
	def get_power(self, purpose):
		return self.timer is not None

	def set_power(self, purpose, on, ok_cb, error_cb):
		try:
			if on:
				self._starter()
			else:
				if self.timer:
					try:
						source_remove(self.timer)
					finally:
						self.timer = None
			ok_cb(self.timer is not None)
		except Exception, e:
			LOG(LOG_ERR, __name__, 'set_power', e)
			error_cb(e)

	def get_status(self, ok_cb, error_cb):
		balances = self._get_br().request_balances()
		LOG(LOG_DEBUG, __name__, 'status', balances)
		balance = balances[0]
		balance = dict(balance,
			time=balance.get('time', datetime.utcnow()).isoformat(),
			)
		ok_cb(balance)

	def fake(self, ):
		db = BankAccountTransaction()
		self.New(dict([(url_from_obj_path(_BankAccountTransaction._dbus_path(n)), Empty) for n, v in db.list('3').items()]))

	# Storage
	def list(self, filter, ok_cb, error_cb):
		db = BankAccountTransaction()
		ok_cb(dict([(url_from_obj_path(_BankAccountTransaction._dbus_path(n)), v) for n, v in db.list(filter).items()]))

	def list_all(self, ok_cb, error_cb):
		db = BankAccountTransaction()
		ok_cb(dict([(url_from_obj_path(_BankAccountTransaction._dbus_path(n)), v) for n, v in db.list_all()]))

	def delete_all(self, ok_cb, error_cb):
		error_cb(DBusException("not applicable"))

	# KeyRing
	def get_opened(self, ok_cb, error_cb):
		if self.pin is not None:
			ok_cb(dict(code='READY'))
		else:
			ok_cb(dict(code='PIN'))

	def opened(self, _status):
		pass

	def open(self, pin, ok_cb, error_cb):
		self.pin = str(pin)
		config.set('pin_value', '') # if set manually remove from cfg
		self.Opened(dict(code='READY'))

	# Authorized
	def get_keyring(self):
		return url_from_dbus_obj(self)


from gobject import threads_init as glib_threads_init
glib_threads_init()
from dbus.glib import init_threads as dbus_threads_init
dbus_threads_init()

if __name__ == '__main__':
	from dbus.mainloop.glib import DBusGMainLoop
	from gobject import MainLoop
	from pyneo.cfg_support import ConfigParser
	from syslog import openlog, syslog, closelog, LOG_DAEMON, LOG_NDELAY, LOG_PID, LOG_PERROR
	from pyneo.dbus_support import InitBus, DCN_PYNEOD
	openlog('pybankd', LOG_NDELAY|LOG_PID|LOG_PERROR, LOG_DAEMON, )
	DBusGMainLoop(set_as_default=True)
	mainloop = MainLoop()
	daemon = Daemon(InitBus(DCN_PYNEOD), ConfigParser('/etc/pyneod.ini').get_section_config('bank'))
	mainloop.run()
	closelog()
# vim:tw=0:nowrap

# -*- coding: utf-8 -*-
__author__ = "M. Dietrich <mdt@pyneo.org>"
__version__ = "prototype"
__copyright__ = "Copyright (c) 2009 M. Dietrich"
__license__ = "GPLv3"
__docformat__ = 'reStructuredText'
'''
see file:///usr/share/doc/libaqbanking-doc/aqbanking.html/group__G__AB__BANKING.html

This is a thin wrapper on aqbanking. it is not meant to be complete. It's one &
only goal is to determine transactions on accounts and the current balance.
'''
from datetime import datetime
from hashlib import md5

charencoding = 'utf-8', 'replace',

cdef extern from *:
	ctypedef char* const_char_ptr "const char*"

cdef extern from "gwenhywfar/gwenhywfar.h":
	int GWEN_GUI_FLAGS_NONINTERACTIVE
	int GWEN_LoggerLevel_Debug
	ctypedef struct GWEN_GUI:
		pass
	ctypedef struct GWEN_TIME:
		pass
	ctypedef GWEN_TIME* const_GWEN_TIME_ptr "const GWEN_TIME*"
	int GWEN_Init() nogil
	int GWEN_Fini() nogil
	int GWEN_Logger_Open(int, const_char_ptr, int, int, int) nogil
	int GWEN_LoggerType_Console
	int GWEN_LoggerType_Syslog
	int GWEN_LoggerFacility_User
	int GWEN_LoggerFacility_Daemon
	int GWEN_LoggerLevel_Warning
	void GWEN_Logger_SetLevel(int, int) nogil
	int GWEN_Logger_Log(const_char_ptr, int, const_char_ptr) nogil
	void GWEN_Logger_Close(const_char_ptr) nogil
	void GWEN_Gui_CGui_SetCharSet(GWEN_GUI*, const_char_ptr) nogil
	void GWEN_Gui_SetFlags(GWEN_GUI*, int) nogil
	void GWEN_Gui_AddFlags(GWEN_GUI*, int) nogil
	void GWEN_Gui_SubFlags(GWEN_GUI*, int) nogil
	void GWEN_Gui_SetGui(GWEN_GUI*) nogil
	GWEN_TIME* GWEN_Time_fromUtcString(const_char_ptr, const_char_ptr) nogil
	void GWEN_Time_free(GWEN_TIME*) nogil
	int GWEN_Time_GetBrokenDownTime(GWEN_TIME*, int*, int*, int*) nogil
	int GWEN_Time_GetBrokenDownUtcTime(GWEN_TIME*, int*, int*, int*) nogil
	int GWEN_Time_GetBrokenDownDate(GWEN_TIME*, int*, int*, int*) nogil
	int GWEN_Time_GetBrokenDownUtcDate(GWEN_TIME*, int*, int*, int*) nogil
	int GWEN_Time_toTime_t(GWEN_TIME*) nogil
	void GWEN_Gui_free(GWEN_GUI*) nogil

cdef extern from "gwenhywfar/db.h":
	int GWEN_DB_FLAGS_DEFAULT
	ctypedef struct GWEN_DB_NODE:
		pass
	GWEN_DB_NODE* GWEN_DB_Group_new(const_char_ptr) nogil
	int GWEN_DB_SetCharValue(GWEN_DB_NODE*, int, const_char_ptr, const_char_ptr) nogil
	void GWEN_DB_Group_free(GWEN_DB_NODE*) nogil
	int GWEN_DB_WriteFile(GWEN_DB_NODE*, const_char_ptr, int, int, int) nogil

cdef extern from "gwenhywfar/stringlist.h":
	ctypedef struct GWEN_STRINGLIST:
		pass
	ctypedef struct GWEN_STRINGLISTENTRY:
		pass
	GWEN_STRINGLISTENTRY* GWEN_StringList_FirstEntry(GWEN_STRINGLIST*) nogil
	char *GWEN_StringListEntry_Data(GWEN_STRINGLISTENTRY*) nogil
	GWEN_STRINGLISTENTRY* GWEN_StringListEntry_Next(GWEN_STRINGLISTENTRY*) nogil

cdef extern from "gwenhywfar/buffer.h":
	ctypedef struct GWEN_BUFFER:
		pass
	GWEN_BUFFER *GWEN_Buffer_new(char *buffer, int size, int used, int take_ownership) nogil
	char *GWEN_Buffer_GetStart(GWEN_BUFFER *bf) nogil
	void GWEN_Buffer_free(GWEN_BUFFER *bf) nogil

cdef extern from "gwenhywfar/cgui.h":
	GWEN_GUI* GWEN_Gui_CGui_new() nogil
	void GWEN_Gui_CGui_SetPasswordDb(GWEN_GUI*, GWEN_DB_NODE*, int) nogil

cdef extern from "aqbanking/banking.h":
	ctypedef struct AB_BANKING:
		pass
	ctypedef struct AB_JOB_LIST2:
		pass
	ctypedef struct AB_JOB:
		pass
	ctypedef struct AB_IMEXPORTER_CONTEXT:
		pass
	ctypedef struct AB_ACCOUNT_LIST2_ITERATOR:
		pass
	ctypedef struct AB_ACCOUNT_LIST2:
		pass
	ctypedef struct AB_ACCOUNT:
		pass
	ctypedef struct AB_IMEXPORTER_ACCOUNTINFO:
		pass
	ctypedef struct AB_TRANSACTION:
		pass
	ctypedef struct AB_VALUE:
		pass
	ctypedef struct AB_ACCOUNT_STATUS:
		pass
	ctypedef struct AB_BALANCE:
		pass
	AB_BANKING* AB_Banking_new(const_char_ptr, const_char_ptr, int) nogil
	void AB_Banking_free(AB_BANKING*) nogil
	int AB_Banking_Init(AB_BANKING*) nogil
	int AB_Banking_OnlineInit(AB_BANKING*) nogil
	AB_JOB_LIST2* AB_Job_List2_new() nogil
	void AB_Job_List2_free(AB_JOB_LIST2*) nogil
	void AB_Job_List2_PushBack(AB_JOB_LIST2*, AB_JOB*) nogil
	int AB_Banking_ExecuteJobs(AB_BANKING*, AB_JOB_LIST2*, AB_IMEXPORTER_CONTEXT*) nogil
	int AB_Banking_OnlineFini(AB_BANKING*) nogil
	int AB_Banking_Fini(AB_BANKING*) nogil
	AB_ACCOUNT_LIST2* AB_Banking_GetAccounts(AB_BANKING*) nogil
	AB_ACCOUNT_LIST2_ITERATOR* AB_Account_List2_First(AB_ACCOUNT_LIST2*) nogil
	AB_ACCOUNT* AB_Account_List2Iterator_Data(AB_ACCOUNT_LIST2_ITERATOR*) nogil
	AB_ACCOUNT* AB_Account_List2Iterator_Next(AB_ACCOUNT_LIST2_ITERATOR*) nogil
	void AB_Account_List2Iterator_free(AB_ACCOUNT_LIST2_ITERATOR*) nogil
	const_char_ptr AB_Account_GetBankCode(AB_ACCOUNT*) nogil
	const_char_ptr AB_Account_GetBankName(AB_ACCOUNT*) nogil
	const_char_ptr AB_Account_GetAccountNumber(AB_ACCOUNT*) nogil
	const_char_ptr AB_Account_GetAccountName(AB_ACCOUNT*) nogil
	int AB_Job_CheckAvailability(AB_JOB*) nogil
	void AB_JobGetTransactions_SetFromTime(AB_JOB*, GWEN_TIME*) nogil
	void AB_JobGetTransactions_SetToTime(AB_JOB*, GWEN_TIME*) nogil
	AB_IMEXPORTER_CONTEXT* AB_ImExporterContext_new() nogil
	void AB_ImExporterContext_free(AB_IMEXPORTER_CONTEXT*) nogil
	AB_IMEXPORTER_ACCOUNTINFO* AB_ImExporterContext_GetFirstAccountInfo(AB_IMEXPORTER_CONTEXT*) nogil
	AB_IMEXPORTER_ACCOUNTINFO* AB_ImExporterContext_GetNextAccountInfo(AB_IMEXPORTER_CONTEXT*) nogil
	AB_TRANSACTION* AB_ImExporterAccountInfo_GetFirstTransaction(AB_IMEXPORTER_ACCOUNTINFO*) nogil
	AB_TRANSACTION* AB_ImExporterAccountInfo_GetNextTransaction(AB_IMEXPORTER_ACCOUNTINFO*) nogil
	const_char_ptr AB_Transaction_GetLocalCountry(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalBankCode(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalBranchId(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalAccountNumber(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalSuffix(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalIban(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalName(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetLocalBic(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteCountry(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteBankName(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteBankLocation(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteBankCode(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteBranchId(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteAccountNumber(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteSuffix(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetRemoteIban(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetTransactionKey(AB_TRANSACTION*) nogil
	const_char_ptr AB_Transaction_GetCustomerReference(AB_TRANSACTION *el) nogil
	const_char_ptr AB_Transaction_GetBankReference(AB_TRANSACTION *el) nogil
	int AB_Transaction_GetTransactionCode(AB_TRANSACTION *el) nogil
	const_char_ptr AB_Transaction_GetTransactionText(AB_TRANSACTION *el) nogil
	const_char_ptr AB_Transaction_GetPrimanota(AB_TRANSACTION *el) nogil
	const_char_ptr AB_Transaction_GetFiId(AB_TRANSACTION *el) nogil
	ctypedef GWEN_STRINGLIST* const_GWEN_STRINGLIST_ptr "const GWEN_STRINGLIST*"
	const_GWEN_STRINGLIST_ptr AB_Transaction_GetPurpose(AB_TRANSACTION *el) nogil
	const_GWEN_STRINGLIST_ptr AB_Transaction_GetCategory(AB_TRANSACTION *el) nogil
	const_GWEN_TIME_ptr AB_Transaction_GetValutaDate(AB_TRANSACTION*) nogil
	const_GWEN_TIME_ptr AB_Transaction_GetDate(AB_TRANSACTION*) nogil
	ctypedef AB_VALUE* const_AB_VALUE_ptr "const AB_VALUE*"
	ctypedef AB_BALANCE* const_AB_BALANCE_ptr "const AB_BALANCE*"
	const_AB_VALUE_ptr AB_Transaction_GetValue(AB_TRANSACTION*) nogil
	const_AB_VALUE_ptr AB_Transaction_GetFees(AB_TRANSACTION*) nogil
	void AB_Value_toString(AB_VALUE*, GWEN_BUFFER*) nogil
	void AB_Value_toHumanReadableString(AB_VALUE*, GWEN_BUFFER*, int) nogil
	#void AB_Value_toHumanReadableString2(AB_VALUE*, GWEN_BUFFER*, int, int) nogil
	const_char_ptr AB_Value_GetCurrency(AB_VALUE*) nogil
	double AB_Value_GetValueAsDouble(AB_VALUE*) nogil
	void AB_Job_free(AB_JOB*) nogil

cdef extern from "aqbanking/abgui.h":
	void AB_Gui_Extend(GWEN_GUI*, AB_BANKING*) nogil

cdef extern from "aqbanking/jobgetbalance.h":
	AB_JOB* AB_JobGetBalance_new(AB_ACCOUNT*) nogil
	AB_ACCOUNT_STATUS* AB_ImExporterAccountInfo_GetFirstAccountStatus(AB_IMEXPORTER_ACCOUNTINFO*) nogil
	AB_ACCOUNT_STATUS* AB_ImExporterAccountInfo_GetNextAccountStatus(AB_IMEXPORTER_ACCOUNTINFO*) nogil
	const_AB_BALANCE_ptr AB_AccountStatus_GetNotedBalance(AB_ACCOUNT_STATUS*) nogil
	const_AB_BALANCE_ptr AB_AccountStatus_GetBookedBalance(AB_ACCOUNT_STATUS*) nogil
	const_AB_VALUE_ptr AB_Balance_GetValue(AB_BALANCE*) nogil
	GWEN_TIME* AB_AccountStatus_GetTime(AB_ACCOUNT_STATUS*) nogil
	AB_VALUE* AB_AccountStatus_GetBankLine(AB_ACCOUNT_STATUS*) nogil
	AB_VALUE* AB_AccountStatus_GetDisposable(AB_ACCOUNT_STATUS*) nogil
	AB_VALUE* AB_AccountStatus_GetDisposed(AB_ACCOUNT_STATUS*) nogil

cdef extern from "aqbanking/jobgettransactions.h":
	AB_JOB* AB_JobGetTransactions_new(AB_ACCOUNT*) nogil

cdef class GUI:
	cdef GWEN_GUI* _gui
	cdef GWEN_DB_NODE* _pin
	def __cinit__(self, pin_name=None, pin_value=None, ):
		self._gui = GWEN_Gui_CGui_new()
		if self._gui == NULL:
			raise Exception('GWEN_Gui_CGui_new: NULL')
		if pin_name and pin_value:
			self._pin = GWEN_DB_Group_new('pins')
			if self._pin == NULL:
				raise Exception('GWEN_DB_Group_new: NULL')
			GWEN_DB_SetCharValue(self._pin, 0, pin_name, pin_value)
			GWEN_Gui_CGui_SetPasswordDb(self._gui, self._pin, 1)
			GWEN_Gui_AddFlags(self._gui, GWEN_GUI_FLAGS_NONINTERACTIVE)
		else:
			self._pin = NULL
			GWEN_Gui_SubFlags(self._gui, GWEN_GUI_FLAGS_NONINTERACTIVE)
		GWEN_Gui_SetGui(self._gui)
	def __dealloc__(self):
		if self._pin != NULL:
			GWEN_DB_Group_free(self._pin)
		GWEN_Gui_free(self._gui)
	def __repr__(self):
		return 'bank.GUI()'

cdef class BANKING:
	cdef AB_BANKING* _banking
	def __cinit__(self, GUI gui, config_dir, ):
		self._banking = AB_Banking_new('pyneod', config_dir, 0)
		if self._banking == NULL:
			raise Exception('AB_Banking_new: NULL')
		AB_Gui_Extend(gui._gui, self._banking)
		cdef int rv
		rv = AB_Banking_Init(self._banking)
		if rv < 0:
			raise Exception('AB_Banking_Init: %d'% rv)
		rv = AB_Banking_OnlineInit(self._banking)
		if rv < 0:
			raise Exception('AB_Banking_OnlineInit: %d'% rv)
	def __dealloc__(self):
		AB_Banking_OnlineFini(self._banking)
		AB_Banking_Fini(self._banking)
		AB_Banking_free(self._banking)
	def __repr__(self):
		return 'bank.BANKING()'

cdef class ACCOUNT_LIST:
	cdef AB_ACCOUNT_LIST2* _account_list
	cdef AB_ACCOUNT_LIST2_ITERATOR* _account_list_iterator
	cdef AB_ACCOUNT* _account
	def __cinit__(self, BANKING banking):
		with nogil:
			self._account_list = AB_Banking_GetAccounts(banking._banking)
		if self._account_list == NULL:
			raise Exception('no accounts')
		self._account_list_iterator = AB_Account_List2_First(self._account_list)
		if self._account_list_iterator:
			self._account = AB_Account_List2Iterator_Data(self._account_list_iterator)
		else:
			self._account = NULL
	def __iter__(self):
		return self
	def __next__(self):
		if self._account:
			account = ACCOUNT(self)
			self._account = AB_Account_List2Iterator_Next(self._account_list_iterator)
			return account
		raise StopIteration()
	def __dealloc__(self):
		if self._account_list_iterator:
			AB_Account_List2Iterator_free(self._account_list_iterator)
	def __repr__(self):
		return 'bank.ACCOUNT_LIST()'

cdef class ACCOUNT:
	cdef AB_ACCOUNT* _account
	def __cinit__(self, ACCOUNT_LIST account_list):
		self._account = account_list._account
	property bank_code:
		def __get__(self):
			cdef const_char_ptr r = AB_Account_GetBankCode(self._account)
			if r: return r
	property bank_name:
		def __get__(self):
			cdef const_char_ptr r = AB_Account_GetBankName(self._account)
			if r: return r
	property account_number:
		def __get__(self):
			cdef const_char_ptr r = AB_Account_GetAccountNumber(self._account)
			if r: return r
	property accout_name:
		def __get__(self):
			cdef const_char_ptr r = AB_Account_GetAccountName(self._account)
			if r: return r
	def __repr__(self):
		return 'bank.ACCOUNT("%s", "%s", "%s", "%s")'% (self.bank_name, self.bank_code,
			self.accout_name, self.account_number, )

cdef class TIME:
	cdef GWEN_TIME* _time
	def __cinit__(self, t):
		if isinstance(t, datetime):
			s = t.isoformat()[:19]
			self._time = GWEN_Time_fromUtcString(s.encode(), b"YYYY-MM-DDThh:mm:ss")
			if self._time == NULL:
				raise Exception('GWEN_Time_fromUtcString: NULL')
		else:
			raise Exception('unkown type')
	def __dealloc__(self):
		GWEN_Time_free(self._time)
	def __repr__(self):
		return 'bank.TIME(%d)'% GWEN_Time_toTime_t(self._time)

cdef class JOB:
	cdef AB_JOB* _job
	def __dealloc__(self):
		if self._job != NULL:
			AB_Job_free(self._job)
	def __repr__(self):
		return 'bank.JOB()'

cdef class JOB_GET_TRANSACTIONS(JOB):
	def __cinit__(self, ACCOUNT account):
		self._job = AB_JobGetTransactions_new(account._account)
		if self._job == NULL:
			raise Exception('AB_JobGetTransactions_new: NULL')
		cdef int rv
		rv = AB_Job_CheckAvailability(self._job)
		if rv < 0:
			raise Exception('Job GetTransactions not avaiable: %d'% rv)
	property from_time:
		def __get__(self):
			pass
		def __set__(self, TIME t):
			AB_JobGetTransactions_SetFromTime(self._job, t._time)
	property to_time:
		def __get__(self):
			pass
		def __set__(self, TIME t):
			AB_JobGetTransactions_SetToTime(self._job, t._time)
	def __repr__(self):
		return 'bank.JOB_GET_TRANSACTIONS()'

cdef class JOB_GET_BALANCE(JOB):
	def __cinit__(self, ACCOUNT account):
		self._job = AB_JobGetBalance_new(account._account)
		if self._job == NULL:
			raise Exception('AB_JobGetBalance_new: NULL')
		cdef int rv
		rv = AB_Job_CheckAvailability(self._job)
		if rv < 0:
			raise Exception('Job GetBalance not avaiable: %d'% rv)
	def __repr__(self):
		return 'bank.JOB_GET_BALANCE()'

cdef class IMEXPORTER_CONTEXT:
	cdef AB_IMEXPORTER_CONTEXT* _context
	cdef AB_IMEXPORTER_ACCOUNTINFO* _accountinfo
	def __cinit__(self):
		self._context = AB_ImExporterContext_new()
		if self._context == NULL:
			raise Exception('AB_ImExporterContext_new: NULL')
		self._accountinfo = NULL
	def __iter__(self):
		return self
	def __dealloc__(self):
		AB_ImExporterContext_free(self._context)
	def __repr__(self):
		return 'bank.IMEXPORTER_CONTEXT()'

cdef class TX_IMEXPORTER_CONTEXT(IMEXPORTER_CONTEXT):
	def __next__(self):
		if self._accountinfo == NULL:
			self._accountinfo = AB_ImExporterContext_GetFirstAccountInfo(self._context)
		else:
			self._accountinfo = AB_ImExporterContext_GetNextAccountInfo(self._context)
		if self._accountinfo:
			return TX_IMEXPORTER_ACCOUNTINFO(self)
		raise StopIteration()

cdef class BL_IMEXPORTER_CONTEXT(IMEXPORTER_CONTEXT):
	def __next__(self):
		if self._accountinfo == NULL:
			self._accountinfo = AB_ImExporterContext_GetFirstAccountInfo(self._context)
		else:
			self._accountinfo = AB_ImExporterContext_GetNextAccountInfo(self._context)
		if self._accountinfo:
			return BL_IMEXPORTER_ACCOUNTINFO(self)
		raise StopIteration()

cdef class JOBLIST:
	cdef AB_JOB_LIST2* _job_list
	cdef AB_BANKING* _banking
	def __cinit__(self, BANKING banking):
		with nogil:
			self._job_list = AB_Job_List2_new()
		if self._job_list == NULL:
			raise Exception('AB_Job_List2_new: NULL')
		self._banking = banking._banking
	def push_back(self, JOB job):
		AB_Job_List2_PushBack(self._job_list, job._job)
	def execute(self, IMEXPORTER_CONTEXT ctx):
		cdef int rv
		with nogil:
			rv = AB_Banking_ExecuteJobs(self._banking, self._job_list, ctx._context)
		if rv != 0:
			raise Exception('Couldn`t execute jobs: %d'% rv)
	def __dealloc__(self):
		if self._job_list != NULL:
			AB_Job_List2_free(self._job_list)
	def __repr__(self):
		return 'bank.JOBLIST()'

cdef class IMEXPORTER_ACCOUNTINFO:
	cdef AB_IMEXPORTER_ACCOUNTINFO* _accountinfo
	def __iter__(self):
		return self
	def __repr__(self):
		return 'bank.IMEXPORTER_ACCOUNTINFO()'

cdef class TX_IMEXPORTER_ACCOUNTINFO(IMEXPORTER_ACCOUNTINFO):
	cdef AB_TRANSACTION* _transaction
	def __cinit__(self, TX_IMEXPORTER_CONTEXT ctx):
		self._accountinfo = ctx._accountinfo
		self._transaction = NULL
	def __next__(self):
		if self._accountinfo != NULL:
			if self._transaction == NULL:
				self._transaction = AB_ImExporterAccountInfo_GetFirstTransaction(self._accountinfo)
			else:
				self._transaction = AB_ImExporterAccountInfo_GetNextTransaction(self._accountinfo)
			if self._transaction:
				return TRANSACTION(self)
		raise StopIteration()

cdef class BL_IMEXPORTER_ACCOUNTINFO(IMEXPORTER_ACCOUNTINFO):
	cdef AB_ACCOUNT_STATUS* _account_status
	def __cinit__(self, BL_IMEXPORTER_CONTEXT ctx):
		self._accountinfo = ctx._accountinfo
		self._account_status = NULL
	def __next__(self):
		if self._accountinfo != NULL:
			if self._account_status == NULL:
				self._account_status = AB_ImExporterAccountInfo_GetFirstAccountStatus(self._accountinfo)
			else:
				self._account_status = AB_ImExporterAccountInfo_GetNextAccountStatus(self._accountinfo)
			if self._account_status:
				return ACCOUNT_STATUS(self)
		raise StopIteration()

cdef class TRANSACTION:
	cdef AB_TRANSACTION* _transaction
	def __cinit__(self, TX_IMEXPORTER_ACCOUNTINFO accountinfo):
		self._transaction = accountinfo._transaction
	property local_country:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalCountry(self._transaction)
			if r: return r
	property local_bank_code:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalBankCode(self._transaction)
			if r: return r
	property local_branch_id:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalBranchId(self._transaction)
			if r: return r
	property local_account_number:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalAccountNumber(self._transaction)
			if r: return r
	property local_suffix:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalSuffix(self._transaction)
			if r: return r
	property local_iban:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalIban(self._transaction)
			if r: return r
	property local_name:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalName(self._transaction)
			if r: return r
	property local_bic:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetLocalBic(self._transaction)
			if r: return r
	property remote_country:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteCountry(self._transaction)
			if r: return r
	property remote_bank_name:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteBankName(self._transaction)
			if r: return r
	property remote_bank_location:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteBankLocation(self._transaction)
			if r: return r
	property remote_bank_code:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteBankCode(self._transaction)
			if r: return r
	property remote_branch_id:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteBranchId(self._transaction)
			if r: return r
	property remote_account_number:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteAccountNumber(self._transaction)
			if r: return r
	property remote_suffix:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteSuffix(self._transaction)
			if r: return r
	property remote_iban:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetRemoteIban(self._transaction)
			if r: return r
	property transaction_text:
		def __get__(self):
			cdef const_char_ptr r = AB_Transaction_GetTransactionText(self._transaction)
			if r: return unicode(r, *charencoding)
	property value:
		def __get__(self):
			cdef const_AB_VALUE_ptr v = AB_Transaction_GetValue(self._transaction)
			cdef double _buffer = 0.0
			if v:
				_buffer = AB_Value_GetValueAsDouble(v)
				s = float(_buffer)
				return s
	property value_currency:
		def __get__(self):
			cdef const_AB_VALUE_ptr v = AB_Transaction_GetValue(self._transaction)
			if v:
				return AB_Value_GetCurrency(v)
	property fees:
		def __get__(self):
			cdef const_AB_VALUE_ptr v = AB_Transaction_GetFees(self._transaction)
			cdef double _buffer = 0.0
			if v:
				_buffer = AB_Value_GetValueAsDouble(v)
				s = float(_buffer)
				return s
	property valuta_date:
		def __get__(self):
			cdef const_GWEN_TIME_ptr _time = AB_Transaction_GetValutaDate(self._transaction)
			if _time: return datetime.utcfromtimestamp(GWEN_Time_toTime_t(_time))
	property date:
		def __get__(self):
			cdef const_GWEN_TIME_ptr _time = AB_Transaction_GetDate(self._transaction)
			if _time: return datetime.utcfromtimestamp(GWEN_Time_toTime_t(_time))
	property purpose:
		def __get__(self):
			cdef const_GWEN_STRINGLIST_ptr _stringlist = AB_Transaction_GetPurpose(self._transaction)
			cdef GWEN_STRINGLISTENTRY* _stringlistentry = GWEN_StringList_FirstEntry(_stringlist)
			cdef const_char_ptr s
			ret = None
			while _stringlistentry:
				s = GWEN_StringListEntry_Data(_stringlistentry)
				if ret is None:
					ret = s
				else:
					ret += b' '
					ret += s
				_stringlistentry = GWEN_StringListEntry_Next(_stringlistentry)
			if ret: return unicode(ret, *charencoding)
	property category:
		def __get__(self):
			cdef const_GWEN_STRINGLIST_ptr _stringlist = AB_Transaction_GetCategory(self._transaction)
			cdef GWEN_STRINGLISTENTRY* _stringlistentry = GWEN_StringList_FirstEntry(_stringlist)
			cdef const_char_ptr s
			ret = None
			while _stringlistentry:
				s = GWEN_StringListEntry_Data(_stringlistentry)
				if ret is None:
					ret = s
				else:
					ret += b' '
					ret += s
				_stringlistentry = GWEN_StringListEntry_Next(_stringlistentry)
			if ret: return unicode(ret, *charencoding)
	def dict(self):
		ret = dict()
		c = self.purpose
		if c: ret['purpose'] = c
		c = self.category
		if c: ret['category'] = c
		c = self.value
		if c: ret['value'] = c
		c = self.value_currency
		if c: ret['value_currency'] = c
		c = self.fees
		if c: ret['fees'] = c
		cdef const_char_ptr r
		r = AB_Transaction_GetLocalCountry(self._transaction)
		if r: ret['local_country'] = r
		r = AB_Transaction_GetLocalBankCode(self._transaction)
		if r: ret['local_bank_code'] = r
		r = AB_Transaction_GetLocalBranchId(self._transaction)
		if r: ret['local_branch_id'] = r
		r = AB_Transaction_GetLocalAccountNumber(self._transaction)
		if r: ret['local_account_number'] = r
		r = AB_Transaction_GetLocalSuffix(self._transaction)
		if r: ret['local_suffix'] = r
		r = AB_Transaction_GetLocalIban(self._transaction)
		if r: ret['local_iban'] = r
		r = AB_Transaction_GetLocalName(self._transaction)
		if r: ret['local_name'] = r
		r = AB_Transaction_GetLocalBic(self._transaction)
		if r: ret['local_bic'] = r
		r = AB_Transaction_GetRemoteCountry(self._transaction)
		if r: ret['remote_country'] = r
		r = AB_Transaction_GetRemoteBankName(self._transaction)
		if r: ret['remote_bank_name'] = r
		r = AB_Transaction_GetRemoteBankLocation(self._transaction)
		if r: ret['remote_bank_location'] = r
		r = AB_Transaction_GetRemoteBankCode(self._transaction)
		if r: ret['remote_bank_code'] = r
		r = AB_Transaction_GetRemoteBranchId(self._transaction)
		if r: ret['remote_branch_id'] = r
		r = AB_Transaction_GetRemoteAccountNumber(self._transaction)
		if r: ret['remote_account_number'] = r
		r = AB_Transaction_GetRemoteSuffix(self._transaction)
		if r: ret['remote_suffix'] = r
		r = AB_Transaction_GetRemoteIban(self._transaction)
		if r: ret['remote_iban'] = r
		r = AB_Transaction_GetTransactionText(self._transaction)
		if r: ret['transaction_text'] = unicode(r, *charencoding)
		cdef const_GWEN_TIME_ptr _time
		_time = AB_Transaction_GetValutaDate(self._transaction)
		if _time: ret['valuta_date'] = datetime.utcfromtimestamp(GWEN_Time_toTime_t(_time))
		_time =AB_Transaction_GetDate(self._transaction)
		if _time: ret['date'] = datetime.utcfromtimestamp(GWEN_Time_toTime_t(_time))
		m = md5()
		m.update('|'.join((
			str(self.local_account_number),
			str(self.local_bank_code),
			str(self.remote_account_number),
			str(self.remote_bank_code),
			str(self.value),
			str(self.valuta_date),
			)).encode())
		ret['ui'] = m.hexdigest()
		return ret
	def __repr__(self):
		return 'bank.TRANSACTION: %s %s %s %s %s %s'% (self.date, self.local_account_number, self.remote_bank_code, self.remote_account_number, self.transaction_text, self.value, )

cdef class ACCOUNT_STATUS:
	cdef AB_ACCOUNT_STATUS* _account_status
	def __cinit__(self, BL_IMEXPORTER_ACCOUNTINFO ai):
		self._account_status = ai._account_status
	property noted_balance:
		def __get__(self):
			cdef const_AB_BALANCE_ptr b = AB_AccountStatus_GetNotedBalance(self._account_status)
			cdef const_AB_VALUE_ptr v = NULL
			cdef double _buffer = 0.0
			if b:
				v = AB_Balance_GetValue(b)
				if v:
					_buffer = AB_Value_GetValueAsDouble(v)
					s = float(_buffer)
					return s
	property booked_balance:
		def __get__(self):
			cdef const_AB_BALANCE_ptr b = AB_AccountStatus_GetBookedBalance(self._account_status)
			cdef const_AB_VALUE_ptr v = NULL
			cdef double _buffer = 0.0
			if b:
				v = AB_Balance_GetValue(b)
				if v:
					_buffer = AB_Value_GetValueAsDouble(v)
					s = float(_buffer)
					return s
	property time:
		def __get__(self):
			cdef const_GWEN_TIME_ptr _time = AB_AccountStatus_GetTime(self._account_status)
			if _time: return datetime.utcfromtimestamp(GWEN_Time_toTime_t(_time))
	property bankline:
		def __get__(self):
			cdef const_AB_VALUE_ptr v = AB_AccountStatus_GetBankLine(self._account_status)
			cdef double _buffer = 0.0
			if v:
				_buffer = AB_Value_GetValueAsDouble(v)
				s = float(_buffer)
				return s
	property disposable:
		def __get__(self):
			cdef const_AB_VALUE_ptr v = AB_AccountStatus_GetDisposable(self._account_status)
			cdef double _buffer = 0.0
			if v:
				_buffer = AB_Value_GetValueAsDouble(v)
				s = float(_buffer)
				return s
	property disposed:
		def __get__(self):
			cdef const_AB_VALUE_ptr v = AB_AccountStatus_GetDisposed(self._account_status)
			cdef double _buffer = 0.0
			if v:
				_buffer = AB_Value_GetValueAsDouble(v)
				s = float(_buffer)
				return s
	def dict(self):
		ret = dict()
		c = self.noted_balance
		if c: ret['noted_balance'] = c
		c = self.booked_balance
		if c: ret['booked_balance'] = c
		c = self.time
		if c: ret['time'] = c
		c = self.bankline
		if c: ret['bankline'] = c
		c = self.disposable
		if c: ret['disposable'] = c
		c = self.disposed
		if c: ret['disposed'] = c
		return ret

class BankingRequestor:
	def __init__(self, pin_name, pin_value, config_dir, account_numbers, bank_code, ):
		account_numbers = list(account_numbers)
		self.accounts = list()
		self.gui = GUI(pin_name, pin_value)
		self.banking = BANKING(self.gui, config_dir)
		account_list = ACCOUNT_LIST(self.banking)
		for account in account_list:
			if account.account_number in account_numbers\
			and account.bank_code == bank_code:
				account_numbers.remove(account.account_number)
				self.accounts.append(account)
		if account_numbers:
			raise Exception('not all accounts where found: %s'% account_numbers)

	def request_transactions(self, from_time, to_time, ):
		from_time = TIME(from_time)
		to_time = TIME(to_time)
		joblist = JOBLIST(self.banking)
		jobs = list()
		for account in self.accounts:
			job = JOB_GET_TRANSACTIONS(account)
			if from_time:
				job.from_time = from_time
			if to_time:
				job.to_time = to_time
			jobs.append(job)
		for job in jobs:
			joblist.push_back(job)
		context = TX_IMEXPORTER_CONTEXT()
		joblist.execute(context)
		ret = list()
		for accountinfo in context:
			for transaction in accountinfo:
				ret.append(transaction.dict()) # TODO: yield!
		return ret

	def request_balances(self, ):
		joblist = JOBLIST(self.banking)
		jobs = list()
		for account in self.accounts:
			job = JOB_GET_BALANCE(account)
			jobs.append(job)
		for job in jobs:
			joblist.push_back(job)
		context = BL_IMEXPORTER_CONTEXT()
		joblist.execute(context)
		ret = list()
		for accountinfo in context:
			for balance in accountinfo:
				ret.append(balance.dict()) # TODO: yield!
		return ret

	def __repr__(self):
		return 'bank.BankingRequestor()'

class BLZCheck(object):
	def __init__(self, filename='/var/lib/ktoblzcheck1/bankdata.txt'):
		self.blz_mapping = self._read(filename)

	def _read(self, filename):
		blz_mapping = dict()
		from os.path import exists
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


cdef _init_module():
	cdef int rv
	rv = GWEN_Init()
	if rv != 0:
		raise Exception('GWEN did not init: %d'% rv)
	if __debug__:
		GWEN_Logger_Open(0, 'pyneod', 0, GWEN_LoggerType_Console, GWEN_LoggerFacility_User)
		GWEN_Logger_SetLevel(0, GWEN_LoggerLevel_Debug)
	else:
		GWEN_Logger_Open(0, 'pyneod', 0, GWEN_LoggerType_Syslog, GWEN_LoggerFacility_Daemon)
		GWEN_Logger_SetLevel(0, GWEN_LoggerLevel_Warning)

#cdef _dealloc_module(): # TODO: find the right name
#	GWEN_Logger_Close('pyneod')
#	GWEN_Fini()
#
_init_module()
# vim:tw=0:nowrap

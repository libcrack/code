#!/usr/bin/env bash

--() { echo; echo "-- $*"; echo; }

. lib.bash

messages() {
	(die "fatal message")
	err "error message"
	warn "warning message"
	notice "notice message"
	TERM= status "status message"
	log2 "log2 message"
	log "log message"
	say "info message"
	debug "debug message"
	true
}

-- 'messages (normal)' --

DEBUG='' messages

-- 'messages ($DEBUG)' --

DEBUG=1 messages

-- 'backtraces ($DEBUG=2)' --

foo() { bar; }
bar() { baz; }
baz() { warn "something failed"; }

DEBUG=2 foo

true
